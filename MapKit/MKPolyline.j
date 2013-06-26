@import "MKMultiPoint.j"

@implementation MKPolyline : MKMultiPoint
{

}

+ (MKPolyline)polylineWithCoordinates:(CPArray)coords count:(CPInteger)count
{
    var points = [];
    for (var i = 0; i < count; i++)
    {
        var p = MKMapPointForCoordinate(coords[i]);
        points.push(p);
    }

    return [MKPolyline polylineWithPoints:points count:count];
}

+ (MKPolyline)polylineWithPoints:(CPArray)points count:(CPInteger)count
{
    return [[MKPolyline alloc] _initWithPoints:points count:count];
}

- (id)_initWithPoints:(CPArray)points count:(CPInteger)count
{
    self = [super init];

    _points = points;
    _pointCount = count;

    return self;
}

- (void)_addPoint:(MKMapPoint)aPoint
{
    _points.push(aPoint);
    _pointCount++;
}

- (void)_addPolyline:(MKPolyline)aPolyline
{
    var points = [aPolyline points];

    [_points addObjectsFromArray:points];
    _pointCount += [points count];
}

@end
