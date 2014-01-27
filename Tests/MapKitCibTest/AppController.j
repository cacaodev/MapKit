/*
 * AppController.j
 * MapKitCibTest
 *
 * Created by You on March 1, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

CPLogRegister(CPLogConsole);

@import <Foundation/CPObject.j>
@import <AppKit/CPArrayController.j>

@import <MapKit/MapKit.j>

@implementation ArrayController : CPArrayController
{
}

- (id)newObject
{
    return [[MKPointAnnotation alloc] init];
}

@end

@implementation AppController : CPObject
{
    @outlet CPWindow  theWindow; //this "outlet" is connected automatically by the Cib
    @outlet MKMapView mapView;
    @outlet CPTableView tableView;

    CPArray annotations @accessors;
    CPArray steps       @accessors;
}

- (id)init
{
    self = [super init];

    annotations = [CPArray array];
    steps = [CPArray array];

    [self addObserver:self forKeyPath:@"annotations" options:CPKeyValueObservingOptionNew context:nil];

    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(void)context
{
    var kind = [change objectForKey:CPKeyValueChangeKindKey];

    if (kind == 2)
    {
        var annotation = [[change objectForKey:CPKeyValueChangeNewKey] firstObject],
            location = [annotation coordinate];

        if (!location)
        {
            location = [mapView centerCoordinate];
            [annotation setCoordinate:location];
        }

        [mapView addAnnotation:annotation];

        if ([annotation isKindOfClass:[MKUserLocation class]])
            return;

        var geocoder = [[MKGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:location completionHandler:function (placemarks, error)
        {
            var country = nil,
                locality = nil;

            if (error)
            {
                country = [error description];
            }
            else
            {
                var placemark = [placemarks firstObject],
                    addressDictionary = [placemark addressDictionary];

                country = [addressDictionary objectForKey:@"country"];
                locality = [addressDictionary objectForKey:@"locality"];
            }

            [annotation setTitle:country];
            [annotation setSubtitle:locality];
        }];
    }
    else if (kind == 3)
    {
        var anns = [change objectForKey:CPKeyValueChangeOldKey];
        [mapView removeAnnotations:anns];
    }
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    var indexes = [[aNotification object] selectedRowIndexes],
        selection = [annotations objectsAtIndexes:indexes];

// change state
}

- (CPArray)selectedAnnotations
{
    return [annotations objectsAtIndexes:[tableView selectedRowIndexes]];
}

- (void)findDirectionsFrom:(MKMapItem)source to:(MKMapItem)destination
{
    var request = [[MKDirectionsRequest alloc] init];
    [request setSource:source];
    [request setDestination:destination];

    CPLog.debug("request " + request);

    var directions = [[MKDirections alloc] initWithRequest:request];

    CPLog.debug("directions " + directions);

    [directions calculateDirectionsWithCompletionHandler:function(response, error)
    {
        var theSteps = [CPArray array];

        if (error == nil)
        {
            CPLog.debug("response " + [response description]);
            var r = [[response routes] firstObject],
                s = [r steps];

            [theSteps addObjectsFromArray:s];
            var polyline = [r polyline];
            [polyline setTitle:"route"];
            [mapView addOverlay:polyline];
        }

        [self setSteps:theSteps];
    }];
}

- (void)renderRouteSteps:(CPArray)theSteps
{
    [theSteps enumerateObjectsUsingBlock:function(aStep, idx, stop)
    {
        var polyline = [aStep polyline],
            start = [[polyline points] firstObject];

        var coordinate = MKCoordinateForMapPoint(start);

        var circle = [MKCircle circleWithCenterCoordinate:coordinate radius:10];
        [mapView addOverlay:circle];
    }];
}

- (IBAction)geocode:(id)sender
{
    var address = [sender stringValue];
    var geocoder = [[MKGeocoder alloc] init];

    [geocoder geocodeAddressString:address inRegion:nil completionHandler:function(placemarks, error)
    {
        if (error)
            CPLogConsole(error);
        else
        {
            var annotation = placemarks[0];

            [self insertObject:annotation inAnnotationsAtIndex:[annotations count]];
            [mapView setCenterCoordinate:[annotation coordinate]];
        }
    }];
}

- (IBAction)showAnnotations:(id)sender
{
    var rowIndexes = [tableView selectedRowIndexes];

    var anns = ([rowIndexes count] > 0) ? [annotations objectsAtIndexes:rowIndexes] : annotations;

    [mapView showAnnotations:anns animated:NO];
}

- (IBAction)setMapType:(id)sender
{
    var type = [sender tagForSegment:[sender selectedSegment]];
    [mapView setMapType:type];
}

- (IBAction)directions:(id)sender
{
    var selection = [self selectedAnnotations];

    if ([selection count] < 2)
        return;

    var p = [[MKPlacemark alloc] init];
    [p setLocation:[[selection firstObject] coordinate]];

    var pp = [[MKPlacemark alloc] init];
    [pp setLocation:[[selection lastObject] coordinate]];

    var start = [[MKMapItem alloc] initWithPlacemark:p],
        end = [[MKMapItem alloc] initWithPlacemark:pp];

    [self findDirectionsFrom:start to:end];
}

- (IBAction)addOverlay:(id)sender
{
    var selection = [self selectedAnnotations];

    if ([selection count] < 2)
        return;

    var c1 = [[selection firstObject] coordinate],
        c2 = [[selection lastObject] coordinate],
        coordinates = [c1, c2];

    var polyline = [MKPolyline polylineWithCoordinates:coordinates count:coordinates.length];
    [polyline setTitle:"direct"];
    [mapView addOverlay:polyline];
}

- (IBAction)removeOverlays:(id)sender
{
    [mapView removeOverlays:[mapView overlays]];
}

- (IBAction)selectAnnotation:(id)sender
{
    var row = [tableView rowForView:sender],
        anns = [annotations objectsAtIndexes:[CPIndexSet indexSetWithIndex:row]];

    [mapView setSelectedAnnotations:anns];
}

- (IBAction)showUserLocation:(id)sender
{
    [mapView setShowsUserLocation:[sender state]];
}

// Accessors
- (void)insertObject:(id)anObject inAnnotationsAtIndex:(CPInteger)anIndex
{
    [annotations insertObject:anObject atIndex:anIndex];
}

- (void)removeObjectFromAnnotationsAtIndex:(unsigned int)index
{
    [annotations removeObjectAtIndex:index];
}

- (id)objectInAnnotationsAtIndex:(CPInteger)anIndex
{
    return [annotations objectAtIndex:anIndex];
}

- (CPInteger)countOfAnnotations
{
    return [annotations count];
}

- (void)awakeFromCib
{
    CPLog.debug(_cmd);
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    CPLog.debug(_cmd + mapView);
    [mapView setVisibleMapRect:MKMapRectMake(135848897.4, 92271183.5, 235520.1, 146944.0)];
}

// Delegate methods
- (void)mapViewDidFinishLoadingMap:(MKMapView)aMapView
{
    CPLog.debug(_cmd + aMapView + [aMapView delegate]);
    //[mapView setVisibleMapRect:MKMapRectMake(135848897.4, 92271183.5, 235520.1, 146944.0)];
}

- (void)mapViewDidFinishRenderingMap:(MKMapView)aMapView fullyRendered:(BOOL)flag
{
    //CPLog.debug(_cmd + aMapView);
}

- (void)mapView:(MKMapView)aMapView regionDidChangeAnimated:(BOOL)animated
{
    //CPLog.debug(_cmd + aMapView);
}

- (void)mapViewWillStartLocatingUser:(MKMapView)aMapView
{
    CPLog.debug(_cmd + aMapView);

    var userLocation = [aMapView userLocation];

    var circle = [MKCircle circleWithCenterCoordinate:[userLocation coordinate] radius:[userLocation _accuracy]];
    [circle setTitle:"circle"];
    [mapView addOverlay:circle];

    [self insertObject:userLocation inAnnotationsAtIndex:[annotations count]];
}

- (void)mapViewDidStopLocatingUser:(MKMapView)aMapView
{
    CPLog.debug(_cmd + aMapView);

    var idx = [annotations indexOfObjectPassingTest:function(obj)
    {
        return [obj isKindOfClass:[MKUserLocation class]];
    }];

    if (idx !== CPNotFound)
        [self removeObjectFromAnnotationsAtIndex:idx];
}

- (void)mapView:(MKMapView)aMapView didFailToLocateUserWithError:(CPError)anError
{
    CPLog.debug(_cmd + anError);
}

- (void)mapView:(MKMapView)aMapView regionDidChangeAnimated:(BOOL)animated
{
    //CPLog.debug(_cmd + aMapView);
}

- (id)mapView:(MKMapView)aMapView rendererForOverlay:(id)anOverlay
{
    CPLog.debug(_cmd + aMapView);
    var title = [anOverlay title],
        renderer = nil;

    if (title == @"direct")
    {
        renderer = [[MKPolylineRenderer alloc] initWithPolyline:anOverlay];
        [renderer setStrokeColor:[CPColor blueColor]];
        [renderer setLineWidth:4.0];
    }
    else if (title == @"route")
    {
        renderer = [[MKPolylineRenderer alloc] initWithPolyline:anOverlay];
        [renderer setStrokeColor:[CPColor orangeColor]];
        [renderer setLineDashPattern:[4,1]];
        [renderer setLineWidth:4.0];
    }
    else if (title == @"circle")
    {
        renderer = [[MKCircleRenderer alloc] initWithCircle:anOverlay];
        [renderer setFillColor:[CPColor redColor]];

        [renderer setStrokeColor:[CPColor whiteColor]];
        [renderer setLineWidth:4];
    }

    return renderer;
}

@end
