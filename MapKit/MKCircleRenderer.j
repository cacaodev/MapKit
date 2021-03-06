@import "MKOverlayPathRenderer.j"

@implementation MKCircleRenderer : MKOverlayPathRenderer
{
}

- (id)initWithCircle:(MKCircle)aPolyline
{
    self = [super initWithOverlay:aPolyline];

    return self;
}

- (MKCircle)circle
{
    return _overlay;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale inContext:(id)context
{
    var path = [self path];

    if (!CGPathIsEmpty(path))
    {
        [self applyFillPropertiesToContext:context atZoomScale:zoomScale];
        [self fillPath:path inContext:context];

        [self applyStrokePropertiesToContext:context atZoomScale:zoomScale];
        [self strokePath:path inContext:context];
    }
}

- (void)createPath
{
    var rect = [self rectForMapRect:[_overlay boundingMapRect]];

    if ([self strokeColor])
    {
        var inset = MIN(CEIL([self lineWidth] / 2) , CGRectGetWidth(rect) / 2);
        rect = CGRectInset(rect, inset, inset);
    }

    _path = CGPathWithEllipseInRect(rect);
}

@end