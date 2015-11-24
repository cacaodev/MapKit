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

    [self addObserver:self forKeyPath:@"annotations" options:CPKeyValueObservingOptionNew|CPKeyValueObservingOptionOld  context:"annotations"];

    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(void)context
{
    if (context !== "annotations")
        return;

    var kind = [change objectForKey:CPKeyValueChangeKindKey];

    if (kind == CPKeyValueChangeInsertion)
    {
        var annotation = [[change objectForKey:CPKeyValueChangeNewKey] firstObject],
            location = [annotation coordinate];

        if (!location)
        {
            location = [mapView centerCoordinate];
            [annotation setCoordinate:location];
        }

        if ([annotation isKindOfClass:[MKPointAnnotation class]] || [annotation isKindOfClass:[MKUserLocation class]])
        {
            [mapView addAnnotation:annotation];
        }
        else if ([annotation isKindOfClass:[MKShape class]])
        {
            [mapView addOverlay:annotation];
            return;
        }

        var geocoder = [[MKGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:location completionHandler:function (placemarks, error)
        {
            var country = nil,
                locality = nil;

            if (error)
            {
                country = "Error";
                locality = [error localizedDescription];
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
    else if (kind == CPKeyValueChangeRemoval)
    {
        var objects = [change objectForKey:CPKeyValueChangeOldKey];

        [objects enumerateObjectsUsingBlock:function(annotation, idx)
        {
            if ([annotation isKindOfClass:[MKPointAnnotation class]] || [annotation isKindOfClass:[MKUserLocation class]])
            {
                [mapView removeAnnotation:annotation];
            }
            else if ([annotation isKindOfClass:[MKShape class]])
            {
                [mapView removeOverlay:annotation];
            }
        }];
    }
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    [self willChangeValueForKey:@"canSelectOne"];
    [self didChangeValueForKey:@"canSelectOne"];

    [self willChangeValueForKey:@"canSelectMany"];
    [self didChangeValueForKey:@"canSelectMany"];
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
    var coordinates = [[self selectedAnnotations] valueForKey:@"coordinate"];

    var polyline = [MKPolyline polylineWithCoordinates:coordinates count:coordinates.length];
    [polyline setTitle:"direct"];

    [self insertObject:polyline inAnnotationsAtIndex:[annotations count]];
}

- (IBAction)selectAnnotation:(id)sender
{
    var row = [tableView rowForView:sender],
        anns = [annotations objectsAtIndexes:[CPIndexSet indexSetWithIndex:row]];

    [mapView setSelectedAnnotations:anns];
}

- (IBAction)removeSelected:(id)sender
{
    var selected  = [tableView selectedRowIndexes];
    [self removeObjectFromAnnotationsAtIndex:[selected firstIndex]];
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

- (void)removeObjectFromAnnotationsAtIndex:(CPInteger)anIndex
{
    [annotations removeObjectAtIndex:anIndex];
}

- (id)objectInAnnotationsAtIndex:(CPInteger)anIndex
{
    return [annotations objectAtIndex:anIndex];
}

- (CPInteger)countOfAnnotations
{
    return [annotations count];
}

- (BOOL)canSelectOne
{
    return [[self selectedAnnotations] count] > 0;
}

- (BOOL)canSelectMany
{
    return [[self selectedAnnotations] count] >= 2;
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
    var w = MKMapRectWorld();
    var coord1 = MKCoordinateForMapPoint(MKMapPointMake(0,0));
    var coord2 = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(w), MKMapRectGetMaxY(w)));
    CPLog.debug(_cmd + coord1 + " " + coord2);
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

    [self insertObject:circle inAnnotationsAtIndex:[annotations count]];
    [self insertObject:userLocation inAnnotationsAtIndex:[annotations count]];
}

- (void)mapViewDidStopLocatingUser:(MKMapView)aMapView
{
    CPLog.debug(_cmd + aMapView);
}

- (void)mapView:(MKMapView)aMapView didFailToLocateUserWithError:(CPError)anError
{
    CPLog.debug(_cmd + [anError description]);
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
        [renderer setLineWidth:2.0];
    }
    else if (title == @"route")
    {
        renderer = [[MKPolylineRenderer alloc] initWithPolyline:anOverlay];
        [renderer setStrokeColor:[CPColor orangeColor]];
        [renderer setLineDashPattern:[4,1]];
        [renderer setLineWidth:4.0];
    }
    else if ([anOverlay isKindOfClass:[MKCircle class]])
    {
        renderer = [[MKCircleRenderer alloc] initWithCircle:anOverlay];
        [renderer setFillColor:[CPColor greenColor]];
        [renderer setAlpha:0.3];

        [renderer setStrokeColor:[CPColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1]];
        [renderer setLineWidth:5];
    }

    return renderer;
}

- (IBAction)setLineWidth:(id)sender
{
    var lineWidth = [sender floatValue],
        overlay = [annotations objectAtIndex:[tableView rowForView:sender]];

    [[mapView _rendererForOverlay:overlay] setLineWidth:lineWidth];
}

- (IBAction)setStrokeColor:(id)sender
{
    var color = [sender color],
        overlay = [annotations objectAtIndex:[tableView rowForView:sender]];

    [[mapView _rendererForOverlay:overlay] setStrokeColor:color];
}

- (CPView)tableView:(CPTableView)aTableView viewForTableColumn:(CPTableColumn)tableColumn row:(CPInteger)row
{
    var object = [self objectInAnnotationsAtIndex:row];

    var identifier;

    if ([object isKindOfClass:MKPointAnnotation] || [object isKindOfClass:MKUserLocation])
        identifier = "annotation";
    else
        identifier = "overlay";

    return [aTableView makeViewWithIdentifier:identifier owner:self];
}

@end
