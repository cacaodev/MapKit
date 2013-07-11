@import "MKShape.j"

@implementation MKCircle : MKShape
{
    MKMapRect              _boundingMapRect @accessors(readonly, getter=boundingMapRect);
    CLLocationDistance     _radius          @accessors(readonly, getter=radius);
    CLLocationCoordinate2D _coordinate      @accessors(readonly, getter=coordinate);
}

+ (MKCircle)circleWithCenterCoordinate:(CLLocationCoordinate2D)coord radius:(CLLocationDistance)radius
{
    return [[MKCircle alloc] initWithCenterCoordinate:coord radius:radius];
}

+ (MKCircle)circleWithMapRect:(MKMapRect)mapRect
{
     return [[MKCircle alloc] initWithMapRect:mapRect];
}

- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)coord radius:(CLLocationDistance)radius
{
    self = [super init];

    _coordinate = coord;
    _radius = radius;

    var midWidth = _radius / 40075017 * MKWORLD_SIZE,
        width = 2 * midWidth;

    var center = MKMapPointForCoordinate(_coordinate);
    _boundingMapRect = MKMapRectMake(center.x - midWidth, center.y - midWidth, width, width);

    return self;
}

- (id)initWithMapRect:(MKMapRect)mapRect
{
    self = [super init];

    _boundingMapRect = mapRect;
    _radius = MKMapRectGetWidth(_boundingMapRect) / 2 * 40075017 / MKWORLD_SIZE;
    _coordinate = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMidX(_boundingMapRect), MKMapRectGetMidY(_boundingMapRect)));

    return self;
}

- (BOOL)intersectsMapRect:(MKMapRect)mapRect
{
    return CGRectIntersectsRect([self boundingMapRect], mapRect);
}

@end