@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@import "MKShape.j"
@import "MKGeometry.j"

@implementation MKMultiPoint : MKShape
{
    CPInteger  _pointCount  @accessors(readonly, getter=pointCount);
    CPArray    _points      @accessors(readonly, getter=points);
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

    return self;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"< %@ %@ pointCount=%d>", [self className], [self UID], _pointCount];
}

@end
