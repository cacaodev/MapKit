/*
 * AppController.j
 * MapKitCibTest
 *
 * Created by You on March 1, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "../../MapKit.j"

@implementation AppController : CPObject
{
    @outlet CPWindow  theWindow; //this "outlet" is connected automatically by the Cib
    @outlet MKMapView mapView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
console.log(_cmd);

    var loc = CLLocationCoordinate2D(0,0);
    var annotation = [[MKAnnotation alloc] init];
    [annotation setCoordinate:loc];
    [mapView setCenterCoordinate:loc];
    [mapView addAnnotation:annotation];

    var mapView2 = [[MKMapView alloc] initWithFrame:CGRectMake(450, 20, 300, 300)];

    var loc = CLLocationCoordinate2D(0,0);
    var annotation = [[MKAnnotation alloc] init];
    [annotation setCoordinate:loc];
    [mapView2 setCenterCoordinate:loc];
    [mapView2 addAnnotation:annotation];
    [[theWindow contentView] addSubview:mapView2];

    var address = @"12 rue de vaugirard, paris, france";
    var geocoder = [[MKGeocoder alloc] init];
    [geocoder geocodeAddressString:address inRegion:nil completionHandler:function(placemarks, error)
    {
        if (error)
            CPLogConsole(error);
        else
        {
            var location = [placemarks[0] coordinate];
            var annotation = [[MKAnnotation alloc] init];
            [annotation setCoordinate:location];

            [mapView setCenterCoordinate:location];
            [mapView addAnnotation:annotation];
        }
    }];
}

- (void)awakeFromCib
{
    [mapView setZoomLevel:20];
}

- (void)mapViewDidFinishLoadingMap:(MKMapView)aMapView
{
    console.log(_cmd);
}

@end
