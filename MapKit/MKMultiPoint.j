@import "MKShape.j"

@implementation MKMultiPoint : MKShape
{
    CPInteger  _pointCount  @accessors(getter=pointCount);
    CPArray    _points      @accessors(getter=points);
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
    var s = "";

    for (var i = 0; i < _pointCount; i++)
        s += _points[i] + ", ";

    return "<" + [self className] + " pointCount:" + _pointCount + ">";
}

@end
