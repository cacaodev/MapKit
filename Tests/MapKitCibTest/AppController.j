/*
 * AppController.j
 * MapKitCibTest
 *
 * Created by You on March 1, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

CPLogRegister(CPLogConsole);

@import <Foundation/CPObject.j>
@import "MapKit/MapKit.j"

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
    if ([annotations count] < 2)
        return;

    var p = [[MKPlacemark alloc] init];
    [p setLocation:[[annotations firstObject] coordinate]];

    var pp = [[MKPlacemark alloc] init];
    [pp setLocation:[[annotations lastObject] coordinate]];

    [mapView addAnnotations:[p, pp]];

    var start = [[MKMapItem alloc] initWithPlacemark:p],
        end = [[MKMapItem alloc] initWithPlacemark:pp];

    [self findDirectionsFrom:start to:end];
}

- (IBAction)addOverlay:(id)sender
{
    if ([annotations count] < 2)
        return;
   
    var coordinates = [];
    [annotations enumerateObjectsUsingBlock:function(ann, idx, stop)
    {
        coordinates.push([ann coordinate]);    
    }];

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
    CPLog.debug(_cmd + aMapView);
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
        [renderer setLineWidth:2.0];
    }
    else if (title == @"circle")
    {
        renderer = [[MKCircleRenderer alloc] initWithCircle:anOverlay];
        [renderer setFillColor:[CPColor blueColor]];

        [renderer setStrokeColor:[CPColor redColor]];
        [renderer setLineWidth:2];
    }
    
    return renderer;
}

@end
