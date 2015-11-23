@import "MKShape.j"

@implementation MKPointAnnotation : MKShape <MKAnnotation>
{
    CLLocationCoordinate2D _coordinate @accessors(property=coordinate);
}

- (id)init
{
    self = [super init];

    _coordinate = nil;

    return self;
}

@end