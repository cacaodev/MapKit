@import "MKRouteStep.j"

@implementation MKRoute : CPObject
{
    CPArray                     _advisoryNotices    @accessors(readonly, getter=advisoryNotices);
    CPTimeInterval              _expectedTravelTime @accessors(readonly, getter=expectedTravelTime);
    CPString                    _name               @accessors(readonly, getter=name);
    CPArray                     _steps              @accessors(readonly, getter=steps);

    MKDirectionsTransportType   _transportType      @accessors(readonly, getter=transportType);
    CLLocationDistance          _distance           @accessors(readonly, getter=distance);
    MKPolyline                  _polyline           @accessors(readonly, getter=polyline);
}

- (id)initWithJSON:(Object)aJSON
{
    self = [super init];

    _name = aJSON.summary;
    _expectedTravelTime = 0;
    _transportType = MKDirectionsTransportTypeAny;
    _advisoryNotices = aJSON.warnings;
    _steps = [CPArray array];
    _distance = 0;
    _polyline = [[MKPolyline alloc] init];

    var legs = aJSON.legs;

    for (var i = 0; i < legs.length; i++)
    {
        var g_leg = legs[i],
            g_steps = g_leg.steps;

        for (var j = 0; j < g_steps.length; j++)
        {
            var g_step = g_steps[j];
            var routeStep = [[MKRouteStep alloc] initWithJSON:g_step];
            [_steps addObject:routeStep];

            if (g_step.distance)
                _distance += g_step.distance.value;

            [_polyline _addPolyline:[routeStep polyline]];

            var transportType = [routeStep transportType];

            if (i == 0)
                _transportType = transportType;
            else if (transportType !== _transportType)
                _transportType = MKDirectionsTransportTypeAny;
        }

        if (g_leg.duration)
            _expectedTravelTime += g_leg.duration.value;
    }

    return self;
}

- (CPString)description
{
    return "<" + [self className] + " name:" + _name + " transportType:" + _transportType + " travelTime:" + _expectedTravelTime + "s. advisoryNotices:" + _advisoryNotices + " distance: " + _distance + "m. polyline:" + _polyline + " steps:" + [_steps description] + ">";
}

@end

/*
bounds	LatLngBounds	The bounds for this route.
copyrights	string	Copyrights text to be displayed for this route.
legs	Array.<DirectionsLeg>	An array of DirectionsLegs, each of which contains information about the steps of which it is composed. There will be one leg for each waypoint or destination specified. So a route with no waypoints will contain one DirectionsLeg and a route with one waypoint will contain two.
overview_path	Array.<LatLng>	An array of LatLngs representing the entire course of this route. The path is simplified in order to make it suitable in contexts where a small number of vertices is required (such as Static Maps API URLs).
warnings	Array.<string>	Warnings to be displayed when showing these directions.
waypoint_order	Array.<number>	If optimizeWaypoints was set to true, this field will contain the re-ordered permutation of the input waypoints. For example, if the input was:
  Origin: Los Angeles
  Waypoints: Dallas, Bangor, Phoenix
  Destination: New York
and the optimized output was ordered as follows:
  Origin: Los Angeles
  Waypoints: Phoenix, Dallas, Bangor
  Destination: New York
then this field will be an Array containing the values [2, 0, 1]. Note that the numbering of waypoints is zero-based.
If any of the input waypoints has stopover set to false, this field will be empty, since route optimization is not available for such queries.
*/