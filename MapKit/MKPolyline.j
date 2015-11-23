@import "MKMultiPoint.j"
@import "CPArray_Additions.j"

@implementation MKPolyline : MKMultiPoint
{
    BOOL _smooth @accessors;
}

+ (MKPolyline)polylineWithCoordinates:(CPArray)coords count:(CPInteger)count
{
    var points = [coords arrayByApplyingBlock:function(coord)
    {
        return MKMapPointForCoordinate(coord);
    }];

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

- (CLLocationCoordinate2D)coordinate
{
    var mapRect = [self boundingMapRect],
        point = MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMidY(mapRect));

    return MKCoordinateForMapPoint(point);
}

@end