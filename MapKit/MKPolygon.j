@import "MKMultiPoint.j"

@implementation MKPolygon : MKMultiPoint
{
    CPArray _interiorPolygons @accessors(readwrite, getter=interiorPolygons, setter=_setInteriorPolygons:);
}

+ (MKPolygon)polygonWithCoordinates:(CLLocationCoordinate2D)coords count:(CPInteger)count
{
    return [MKPolygon polygonWithCoordinates:coords count:count interiorPolygons:nil];
}

+ (MKPolygon)polygonWithCoordinates:(CLLocationCoordinate2D)coords count:(CPInteger)count interiorPolygons:(CPArray)interiorPolygons
{
    var points = [coords arrayByAppyingBlock:function(coord){
        return MKMapPointForCoordinate(coord);
    }];

    return [MKPolygon polygonWithPoints:points count:count interiorPolygons:interiorPolygons];
}

+ (MKPolygon)polygonWithPoints:(CPArray)points count:(CPInteger)count
{
    return [MKPolygon polygonWithPoints:points count:count interiorPolygons:nil];
}

+ (MKPolygon)polygonWithPoints:(CPArray)points count:(CPInteger)count interiorPolygons:(CPArray)interiorPolygons
{
    var polygon = [[MKPolygon alloc] _initWithPoints:points count:count];
    var polys = [[CPArray alloc] initWithArray:interiorPolygons];
    [polygon _setInteriorPolygons:polys];

    return polygon;
}

@end