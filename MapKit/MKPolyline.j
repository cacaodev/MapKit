@import "MKMultiPoint.j"

@implementation MKPolyline : MKMultiPoint
{
    MKMapRect _boundingMapRect;
    BOOL _smooth @accessors;
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
    _boundingMapRect = nil;
    _smooth = NO;

    return self;
}

- (void)_addPoint:(MKMapPoint)aPoint
{
    _points.push(aPoint);
    _pointCount++;
    _boundingMapRect = nil;
}

- (void)_addPolyline:(MKPolyline)aPolyline
{
    var points = [aPolyline points];

    [_points addObjectsFromArray:points];
    _pointCount += [points count];
    _boundingMapRect = nil;
}

- (MKMapRect)boundingMapRect
{
    if (!_boundingMapRect)
        _boundingMapRect = _MKMapRectForPoints(_points, _pointCount);

    return _boundingMapRect;
}

- (BOOL)intersectsMapRect:(MKMapRect)mapRect
{
    return CGRectIntersectsRect([self boundingMapRect], mapRect);
}

- (CLLocationCoordinate2D)coordinate
{
    var mapRect = [self boundingMapRect],
        point = MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMidY(mapRect));

    return MKCoordinateForMapPoint(point);
}

@end

var _MKMapRectForPoints = function(points, pointCount)
{
    if (pointCount === 0)
        return MKMapRectMake(0, 0, 0, 0);

    var originPoint = points[0];

    if (pointCount === 1)
        return MKMapRectMake(originPoint.x, originPoint.y, 0, 0);

    var minPoint = MKMapPointMake(originPoint.x, originPoint.y),
        maxPoint = MKMapPointMake(originPoint.x, originPoint.y);

    for (var i = 1; i < pointCount; i++)
    {
        var p = points[i],
            x = p.x,
            y = p.y;

        if (x < minPoint.x)
            minPoint.x = x;
        else if (x > maxPoint.x)
            maxPoint.x = x;

        if (y < minPoint.y)
            minPoint.y = y;
        else if (y > maxPoint.y)
            maxPoint.y = y;
    }

    return MKMapRectMake(minPoint.x, minPoint.y, maxPoint.x - minPoint.x, maxPoint.y - minPoint.y);
};