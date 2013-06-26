@implementation MKRouteStep : CPObject
{
    CLLocationDistance          _distance       @accessors(getter=distance);
    CPString                    _instructions   @accessors(getter=instructions);
    CPString                    _notice         @accessors(getter=notice);
    MKPolyline                  _polyline       @accessors(getter=polyline);
    MKDirectionsTransportType   _transportType  @accessors(getter=transportType);
}

- (id)initWithJSON:(Object)aJSON
{
    self = [super init];

    _instructions = aJSON.instructions;
    _distance = aJSON.distance ? aJSON.distance.value : 0;
    _polyline = [[MKPolyline alloc] init];
    _transportType = TransportTypeForTravelMode(aJSON.travel_mode);
    _notice = nil;

    var path = aJSON.path;

    for (var i = 0; i < path.length; i++)
    {
        var coordinate = CLLocationCoordinate2DFromLatLng(path[i]),
            point = MKMapPointForCoordinate(coordinate);

        [_polyline _addPoint:point];
    }

    return self;
}

- (CPString)description
{
    return "<" + [self className] + " notice:" + _notice + " instructions:" + _instructions + " distance:" + _distance + " transport:" + _transportType + " polyline:" + [_polyline description] + ">";
}

@end