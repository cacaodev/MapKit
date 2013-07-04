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

    _instructions = stripHTML(aJSON.instructions);
    _distance = aJSON.distance ? aJSON.distance.value : 0;
    _polyline = [[MKPolyline alloc] init];
    _transportType = TransportTypeForTravelMode(aJSON.travel_mode);
    _notice = nil;

    var path = aJSON.path;

    for (var i = 0; i < path.length; i++)
    {
        var latLng = path[i],
            coordinate = CLLocationCoordinate2DFromLatLng(latLng),
            point = MKMapPointForCoordinate(coordinate);

        [_polyline _addPoint:point];
        
        console.log(i + ": " + point + " " + latLng);
    }

    return self;
}

- (CPString)description
{
    return "<" + [self className] + " notice:" + _notice + " instructions:" + _instructions + " distance:" + _distance + " transport:" + _transportType + " polyline:" + [_polyline description] + ">";
}

@end

var stripHTML = function (html)
 {
    return html.replace(/<\/?([a-z][a-z0-9]*)\b[^>]*>?/gi, '');
};