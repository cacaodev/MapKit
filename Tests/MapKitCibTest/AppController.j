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
            var location = [placemarks[0] coordinate];
            [mapView setCenterCoordinate:location];
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

- (id)init
{
    self = [super init];

    annotations = [CPArray array];

    [self addObserver:self forKeyPath:@"annotations" options:CPKeyValueObservingOptionNew context:nil];

    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(void)context
{
    var kind = [change objectForKey:CPKeyValueChangeKindKey];

    if (kind == 2)
    {
        var annotation = [[change objectForKey:CPKeyValueChangeNewKey] firstObject],
            location = [mapView centerCoordinate];

        [annotation setCoordinate:location];
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

    [mapView setSelectedAnnotations:selection];
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
       if (error == nil)
       {
           CPLog.debug("response " + [response description]);
       }
    }];
}

- (IBAction)directions:(id)sender
{
    var indexes = [tableView selectedRowIndexes],
        selection = [annotations objectsAtIndexes:indexes];

    if ([selection count] < 2)
        return;

    var p = [[MKPlacemark alloc] init];
    [p setLocation:[selection[0] coordinate]];

    var pp = [[MKPlacemark alloc] init];
    [pp setLocation:[selection[1] coordinate]];

    [mapView addAnnotations:[p, pp]];

    var start = [[MKMapItem alloc] initWithPlacemark:p],
        end = [[MKMapItem alloc] initWithPlacemark:pp];

    [self findDirectionsFrom:start to:end];
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
    CPLog.debug(_cmd + aMapView);
}

- (void)mapView:(MKMapView)aMapView regionDidChangeAnimated:(BOOL)animated
{
    CPLog.debug(_cmd + aMapView);
}

@end
