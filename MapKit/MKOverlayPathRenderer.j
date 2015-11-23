@import "MKOverlayRenderer.j"

@implementation MKOverlayPathRenderer : MKOverlayRenderer
{
    CPColor   _fillColor       @accessors(property=fillColor);
    CPColor   _strokeColor     @accessors(property=strokeColor);
    float     _lineWidth       @accessors(property=lineWidth);
    CPInteger _lineJoin        @accessors(property=lineJoin);
    CPInteger _lineCap         @accessors(property=lineCap);
    float     _miterLimit      @accessors(property=miterLimit);
    float     _lineDashPhase   @accessors(property=lineDashPhase);
    CPArray   _lineDashPattern @accessors(property=lineDashPattern);

    CGPath _path               @accessors(setter=setPath:);
}

- (id)initWithOverlay:(id)anOverlay
{
    self = [super initWithOverlay:anOverlay];

    _fillColor = nil;
    _strokeColor = nil;
    _lineWidth = 1.0;
    _lineJoin = kCGLineJoinMiter;
    _lineCap = kCGLineCapButt;
    _miterLimit = 10.0;
    _lineDashPhase = 0;
    _lineDashPattern = [];
    _path = nil;

    // TODO: add/remove obervers when on-off screen
    [self addObserver:self forKeyPath:@"fillColor" options:CPKeyValueObservingOptionNew context:"needsDisplay"];
    [self addObserver:self forKeyPath:@"strokeColor" options:CPKeyValueObservingOptionNew context:"needsDisplay"];
    [self addObserver:self forKeyPath:@"lineWidth" options:CPKeyValueObservingOptionNew context:"needsDisplay"];
    [self addObserver:self forKeyPath:@"lineJoin" options:CPKeyValueObservingOptionNew context:"needsDisplay"];
    [self addObserver:self forKeyPath:@"lineCap" options:CPKeyValueObservingOptionNew context:"needsDisplay"];
    [self addObserver:self forKeyPath:@"miterLimit" options:CPKeyValueObservingOptionNew context:"needsDisplay"];
    [self addObserver:self forKeyPath:@"lineDashPhase" options:CPKeyValueObservingOptionNew context:"needsDisplay"];
    [self addObserver:self forKeyPath:@"lineDashPattern" options:CPKeyValueObservingOptionNew context:"needsDisplay"];

    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(void)context
{
    if (context == "needsDisplay")
    {
        [self setNeedsDisplay];
        [self displayIfNeededInMapRect:[_overlay boundingMapRect] zoomScale:_contentScaleFactor];
    }
}

- (void)_setContentScaleFactor:(float)scaleFactor
{
    if (scaleFactor !== _contentScaleFactor)
    {
        [super _setContentScaleFactor:scaleFactor];
        [self invalidatePath];
    }
}

- (CGPath)path
{
    if (!_path)
        [self createPath];

    return _path;
}

- (void)createPath
{
    //Implemented by subclasses
}

- (void)invalidatePath
{
    _path = nil;
    CPLog.debug(_cmd);
}

- (void)applyStrokePropertiesToContext:(CGContext)context atZoomScale:(float)zoomScale
{
    CGContextSetAlpha(context, _alpha);
    CGContextSetStrokeColor(context, _strokeColor);
    CGContextSetLineWidth(context, _lineWidth);
    CGContextSetLineJoin(context, _lineJoin);
    CGContextSetLineCap(context, _lineCap);
    CGContextSetMiterLimit(context, _miterLimit);
    CGContextSetLineDash(context, _lineDashPhase, _lineDashPattern, _lineDashPattern.length);
}

- (void)applyFillPropertiesToContext:(CGContext)context atZoomScale:(float)zoomScale
{
    CGContextSetAlpha(context, _alpha);
    CGContextSetFillColor(context, _fillColor);
}

- (void)fillPath:(CGPath)path inContext:(CGContext)context
{
    if (!_fillColor)
        return;

    CGContextBeginPath(context);
    CGContextAddPath(context, path);
    CGContextClosePath(context);

    CGContextFillPath(context);
}

- (void)strokePath:(CGPath)path inContext:(CGContext)context
{
    if (!_strokeColor)
        return;
    // TODO: inset the strokePath by lineWidth/2 ?
    CGContextBeginPath(context);
    CGContextAddPath(context, path);
    //CGContextClosePath(context);

    CGContextStrokePath(context);
}

@end