/*
 * AppController.j
 * MapKitCibTest
 *
 * Created by You on March 1, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */
 
CPLogRegister(CPLogConsole);

@import <Foundation/CPObject.j>
@import "../../MapKit.j"

@implementation AppController : CPObject
{
    @outlet CPWindow  theWindow; //this "outlet" is connected automatically by the Cib
    @outlet MKMapView mapView;
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

- (IBAction)addPlacemark:(id)sender
{

    var annotation = [[MKPointAnnotation alloc] init];
    [annotation setTitle:@"Title"];
    [annotation setSubtitle:@"subtitle"];
    [annotation setCoordinate:[mapView centerCoordinate]];
    [mapView addAnnotation:annotation];
    
    //var visible = [mapView annotationsInMapRect:[mapView visibleMapRect]];
    
    [mapView showAnnotations:[mapView annotations] animated:NO];

/*
    var mapView2 = [[MKMapView alloc] initWithFrame:CGRectMake(450, 20, 300, 300)];
    var loc = CLLocationCoordinate2D(0,0);
    var annotation = [[MKAnnotation alloc] init];
    [annotation setCoordinate:loc];
    [mapView2 setCenterCoordinate:loc];
    [mapView2 addAnnotation:annotation];
    [[theWindow contentView] addSubview:mapView2];
*/
}

- (void)awakeFromCib
{
    [mapView setZoomLevel:20];
    console.log(_cmd + [theWindow firstResponder]);
}

- (void)mapViewDidFinishLoadingMap:(MKMapView)aMapView
{
    console.log(_cmd + [theWindow firstResponder]);
}

@end
