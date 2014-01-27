@import <Foundation/CPBundle.j>
@import <AppKit/CPImage.j>

@import "MKAnnotationView.j"

@implementation MKPinAnnotationView : MKAnnotationView
{
}

- (id)initWithAnnotation:(id)anAnnotation reuseIdentifier:(CPString)reuseIdentifier
{
    self = [super initWithAnnotation:anAnnotation reuseIdentifier:[self className]];

    var path = [[CPBundle bundleForClass:self] pathForResource:@"PinPurple.png"];
    _image = [[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(39, 32)];
    _draggable = YES;
    _calloutOffset = CGPointMake(0, -32);
    _centerOffset = CGPointMake(9, 32);

    [self setFrame:CGRectMake(0, 0, 64, 78)];

    return self;
}

@end