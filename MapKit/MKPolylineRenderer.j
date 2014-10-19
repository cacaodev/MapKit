@import "MKOverlayPathRenderer.j"

@implementation MKPolylineRenderer : MKOverlayPathRenderer
{
    //BOOL _needsTranslate;
}

- (id)initWithPolyline:(MKPolyline)aPolyline
{
    self = [super initWithOverlay:aPolyline];

//    _needsTranslate = YES;

    return self;
}

- (MKPolyline)polyline
{
    return _overlay;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale inContext:(id)context
{
    CPLog.debug(_cmd + mapRect + zoomScale + context);
    var path = [self path];

    if (!CGPathIsEmpty(path))
    {
        [self applyStrokePropertiesToContext:context atZoomScale:zoomScale];
        [self strokePath:path inContext:context];
    }
}
/*
- (void)TranslateCTMIfNeeded:(id)context zoomScale:(float)zoomScale
{
    if (_needsTranslate)
    {
        var bounds = [_overlay boundingMapRect];
        var width = MKMapRectGetWidth(bounds),
            height = MKMapRectGetHeight(bounds);

        var k = (1 - zoomScale) / 2;

        CGContextTranslateCTM(context, - width * k, - height * k);

        _needsTranslate = NO;
    }
}
*/
- (void)createPath
{
    var points = [_overlay points],
        count = [_overlay pointCount],
        firstPoint = [self pointForMapPoint:points[0]],
        path = CGPathCreateMutable();

    CGPathMoveToPoint(path, NULL, firstPoint.x, firstPoint.y);

    if (![_overlay _smooth] || count < 4)
    {
        for (var i = 1; i < count; i++)
        {
            var p = [self pointForMapPoint:points[i]];
            CGPathAddLineToPoint(path, NULL, p.x, p.y);
        }
    }
    else
    {
        for (var i = 1; i < count - 2; i ++)
        {
            var p = [self pointForMapPoint:points[i]],
                p1 = [self pointForMapPoint:points[i+1]],
                xc = (p.x + p1.x) / 2,
                yc = (p.y + p1.y) / 2;

            CGPathAddQuadCurveToPoint(path, NULL, p.x, p.y, xc, yc)
        }

        // curve through the last two points
        var p = [self pointForMapPoint:points[i]],
            p1 = [self pointForMapPoint:points[i+1]];

        CGPathAddQuadCurveToPoint(path, NULL, p.x, p.y, p1.x, p1.y);
    }

    _path = path;
}

@end