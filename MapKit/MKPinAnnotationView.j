@import "MKAnnotationView.j"

@implementation MKPinAnnotationView : MKAnnotationView
{
}

- (id)initWithAnnotation:(id <MKAnnotation>)anAnnotation reuseIdentifier:(CPString)reuseIdentifier
{
    self = [super initWithAnnotation:anAnnotation reuseIdentifier:[self className]];
    
    var path = [[CPBundle bundleForClass:self] pathForResource:@"PinPurple.png"];
    _image = [[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(39, 32)];
    draggable = YES;
    calloutOffset = CGPointMake(0, -32);
    centerOffset = CGPointMake(9, 32);
    
    return self;
}

@end