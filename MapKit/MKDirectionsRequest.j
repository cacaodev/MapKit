@import <Foundation/CPObject.j>
@import "MKGeometry.j"
@import "MKTypes.j"

@class MKMapItem;
@class CPDate;
@global google;
@global MKDirectionsTransportType;
@typedef MKDirectionsTransportType;

var GOOGLE_TRAVEL_MODES = nil;

@implementation MKDirectionsRequest : CPObject
{
    MKDirectionsTransportType _transportType           @accessors(property=transportType);
    BOOL                      _requestsAlternateRoutes @accessors(property=requestsAlternateRoutes);
    CPDate                    _departureDate           @accessors(property=departureDate);
    CPDate                    _arrivalDate             @accessors(property=arrivalDate);
    MKMapItem                 _source                  @accessors(property=source);
    MKMapItem                 _destination             @accessors(property=destination);
}

+ (Object)g_travelModes
{
    if (!GOOGLE_TRAVEL_MODES)
    {
        var tm = google.maps.TravelMode;
        GOOGLE_TRAVEL_MODES = [tm.DRIVING, tm.WALKING, tm.DRIVING];
    }

    return GOOGLE_TRAVEL_MODES;
}

- (id)init
{
    self = [super init];

    _transportType = MKDirectionsTransportTypeAny;
    _requestsAlternateRoutes = NO;
    _departureDate = nil;
    _arrivalDate = nil;
    _source = nil;
    _destination = nil;

    return self;
}

- (Object)toJSON
{
    return {
        avoidHighways:false, //If true, instructs the Directions service to avoid highways where possible. Optional.
        avoidTolls:false, //If true, instructs the Directions service to avoid toll roads where possible. Optional.
        destination:LatLngFromCLLocationCoordinate2D([[_destination placemark] location]),	//Location of destination. This can be specified as either a string to be geocoded or a LatLng. Required.
        durationInTraffic:true,	//Whether or not we should provide trip duration based on current traffic conditions. Only available to Maps API for Business customers.
        optimizeWaypoints:true, //If set to true, the DirectionService will attempt to re-order the supplied intermediate waypoints to minimize overall cost of the route. If waypoints are optimized, inspect DirectionsRoute.waypoint_order in the response to determine the new ordering.
        origin:LatLngFromCLLocationCoordinate2D([[_source placemark] location]), //Location of origin. This can be specified as either a string to be geocoded or a LatLng. Required.
        provideRouteAlternatives:_requestsAlternateRoutes, //Whether or not route alternatives should be provided. Optional.
        //region: Region code used as a bias for geocoding requests. Optional.
        //transitOptions	TransitOptions	Settings that apply only to requests where travelMode is TRANSIT. This object will have no effect for other travel modes.
        travelMode:TravelModeForTransportType(_transportType),//	Type of routing requested. Required.
        unitSystem:google.maps.UnitSystem.METRIC //	UnitSystem	Preferred unit system to use when displaying distance. Defaults to the unit system used in the country of origin.
        //waypoints	Array.<DirectionsWaypoint>	Array of intermediate waypoints. Directions will be calculated from the origin to the destination by way of each waypoint in this array. The maximum allowed waypoints is 8, plus the origin, and destination. Maps API for Business customers are allowed 23 waypoints, plus the origin, and destination. Waypoints are not supported for transit directions. Optional.
    }
}

@end
