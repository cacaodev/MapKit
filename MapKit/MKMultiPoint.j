@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@import "MKShape.j"
@import "MKGeometry.j"
@import "CPArray_Additions.j"

@implementation MKMultiPoint : MKShape
{
    CPInteger  _pointCount  @accessors(readonly, getter=pointCount);
    CPArray    _points      @accessors(readonly, getter=points);
    MKMapRect  _boundingMapRect;
}

- (void)getCoordinates:(CPArray)coords range:(CPRange)range
{
    for (var i = range.location; i < CPMaxRange(range); i++)
    {
        var coordinate = MKCoordinateForMapPoint(_points[i]);
        coords.push(coordinate);
    }
}

- (id)init
{
    self = [super init];

    _points = [];
    _pointCount = 0;
    _boundingMapRect = nil;

    return self;
}

- (MKMapRect)boundingMapRect
{
    if (!_boundingMapRect)
        _boundingMapRect = _MKMapRectBoundingMapPoints(_points, _pointCount);

    return _boundingMapRect;
}

- (BOOL)intersectsMapRect:(MKMapRect)mapRect
{
    return CGRectIntersectsRect([self boundingMapRect], mapRect);
}

- (CPString)description
{
    return [CPString stringWithFormat:@"< %@ %@ pointCount=%d>", [self className], [self UID], _pointCount];
}

@end

var _MKMapRectBoundingMapPoints = function(points, pointCount)
{
    if (pointCount === 0)
        return MKMapRectMake(0, 0, 0, 0);

    var originPoint = points[0],
        minPoint = MKMapPointCopy(originPoint),
        maxPoint = MKMapPointCopy(originPoint);

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