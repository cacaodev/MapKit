@import <Foundation/CPBundle.j>
@import <AppKit/CPImage.j>

@import "MKAnnotationView.j"

@global google
@class MKPinAnnotationColor

var MKPinAnnotationColorRed  = 0,
    MKPinAnnotationColorGreen = 1,
    MKPinAnnotationColorPurple = 2;

@implementation MKPinAnnotationView : MKAnnotationView
{
    MKPinAnnotationColor  _pinColor     @accessors(getter=pinColor);
    BOOL                  _animatesDrop @accessors(getter=animatesDrop);
}

- (id)initWithAnnotation:(id)anAnnotation reuseIdentifier:(CPString)reuseIdentifier
{
    self = [super initWithAnnotation:anAnnotation reuseIdentifier:[self className]];

    [self setPinColor:MKPinAnnotationColorGreen];

    _draggable = YES;
    _animatesDrop = NO;
    _calloutOffset = CGPointMake(0, -32);
    _centerOffset = CGPointMake(9, 32);

    [self setFrame:CGRectMake(0, 0, 64, 78)];

    return self;
}

- (void)_updateMarkerAndOverlayForMap:(id)aMap
{
    [super _updateMarkerAndOverlayForMap:aMap];
    [self setAnimatesDrop:YES];
}

- (void)setAnimatesDrop:(BOOL)animates
{
    if (_animatesDrop === animates)
        return;

    var anim = animates ? google.maps.Animation.DROP : null;
    _marker.setAnimation(anim);

    _animatesDrop = animates;
}

- (void)setPinColor:(MKPinAnnotationColor)aPinColor
{
    if (_pinColor === aPinColor)
        return;

    var imageName;

    switch (aPinColor)
    {
        case MKPinAnnotationColorRed : imageName = @"PinRed.png";
        break;
        case MKPinAnnotationColorGreen : imageName = @"PinGreen.png";
        break;
        case MKPinAnnotationColorPurple : imageName = @"PinPurple.png";
        default :
    }

    var path = [[CPBundle bundleForClass:self] pathForResource:imageName];
    _image = [[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(39, 32)];

    _pinColor = aPinColor;
}

@end