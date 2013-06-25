@import "MKShape.j"

@implementation MKPointAnnotation : MKShape
{
    CLLocationCoordinate2D _coordinate @accessors(property=coordinate);
}

@end