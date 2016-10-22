@import <Foundation/CPObject.j>

@import "MKGeometry.j"

@global OverlayContainer

var ReusableOverlayViews = [];

@implementation MKOverlayRenderer : CPObject
{
    id     _overlay            @accessors(readonly, getter=overlay);
    float  _alpha              @accessors(property=alpha);
    float  _contentScaleFactor @accessors(setter=_setContentScaleFactor:);
    BOOL   _needsDisplay;
    BOOL   _needsLayout;
    Object _overlayView;
}

+ (void)initialize
{
    OverlayContainer.prototype = new google.maps.OverlayView();

    OverlayContainer.prototype.onAdd = function()
    {
        // Note: an overlay's receipt of onAdd() indicates that
        // the map's panes are now available for attaching
        // the overlay to the map via the DOM.
        // Create the DIV and set some basic attributes.
        var div = document.createElement('div');

        div.style.border = "none";
        div.style.borderWidth = "0px";
        div.style.position = "absolute";
        //div.style.backgroundColor = get_random_color();

        var canvas = document.createElement('canvas');
        div.appendChild(canvas);
        // Set the overlay's div_ property to this DIV
        this._div = div;
        this._canvas = canvas;

        // We add an overlay to a map via one of the map's panes.
        // We'll add this overlay to the overlayImage pane.
        var panes = this.getPanes();
        panes.overlayLayer.appendChild(div);
    };

    OverlayContainer.prototype.onRemove = function()
    {
        this._div.parentNode.removeChild(this._div);
        this.bounds = null;
        this.drawInMap = null;
        //this.didRemove();
    };

    OverlayContainer.prototype.draw = function()
    {
        // Size and position the overlay. We use a southwest and northeast
        // position of the overlay to peg it to the correct position and size.
        // We need to retrieve the projection from this overlay to do this.
        var overlayProjection = this.getProjection();

        // Retrieve the southwest and northeast coordinates of this overlay
        // in latlngs and convert them to pixels coordinates.
        // We'll use these coordinates to resize the DIV.
        var sw = overlayProjection.fromLatLngToDivPixel(this.bounds.getSouthWest());
        var ne = overlayProjection.fromLatLngToDivPixel(this.bounds.getNorthEast());

        // Resize the DIV to fit the indicated dimensions.
        var style = this._div.style,
            width = ne.x - sw.x,
            height = sw.y - ne.y;

        style.left = sw.x + "px";
        style.top = ne.y + "px";
        style.width  = width + "px" ;
        style.height = height + "px";

        var canvas = this._canvas;
        canvas.width = width;
        canvas.height = height;

        var zoomScale = width / this.boundingWidth;

        this.drawInMap(zoomScale, canvas.getContext("2d"));
    };

    OverlayContainer.prototype.context = function()
    {
        return this._canvas.getContext("2d");
    };
}

- (id)initWithOverlay:(id)anOverlay
{
    self = [super init];

    _overlay = anOverlay;
    _alpha = 1.0;
    _contentScaleFactor = 0;
    _needsDisplay = YES;
    _needsLayout = YES;
    _overlayView = nil;

    return self;
}

- (void)_remove
{
    _overlayView.setMap(null);
}

- (void)_addToMap:(MKMapView)aMapView
{
    var boundingMapRect = [_overlay boundingMapRect];

    var drawHandler = function(aZoomScale, aContext)
    {
        [self _setContentScaleFactor:aZoomScale];
        [self drawMapRect:[aMapView visibleMapRect] zoomScale:aZoomScale inContext:aContext];
    };

    _overlayView = new OverlayContainer(aMapView, boundingMapRect, drawHandler);
}
/*
+ (void)enqueueOverlayView:(id)anOverlayView
{
    ReusableOverlayViews.push(anOverlayView);
}

+ (id)dequeueOverlayView
{
    if (ReusableOverlayViews.length == 0)
        return nil;

    return ReusableOverlayViews.pop();
}
*/
- (void)layoutIfNeeded
{
    if (_needsLayout)
    {
        [self layout];
        _needsLayout = NO;
    }
}

- (void)layout
{
    if (_overlayView)
        _overlayView.layout();
}

- (void)displayIfNeededInMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale
{
    if (_overlayView && _needsDisplay && [self canDrawMapRect:mapRect zoomScale:zoomScale])
    {
        [self _drawMapRect:mapRect zoomScale:zoomScale];
        _needsDisplay = NO;
    }
}

- (void)_drawMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale
{
    [self drawMapRect:mapRect zoomScale:zoomScale inContext:_overlayView.context()];
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale inContext:(id)context
{
    // Implemented by subclasses
}

- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale
{
    return YES;
}

- (void)setNeedsDisplay
{
    _needsDisplay = YES;
}

- (void)setNeedsDisplayInMapRect:(MKMapRect)mapRect
{
}

- (void)setNeedsDisplayInMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale
{
}

- (MKMapPoint)convertMapPoint:(MKMapPoint)aMapPoint
{
    return _PointForMapPoint(aMapPoint, [_overlay boundingMapRect], 1.0);
}

- (CGPoint)pointForMapPoint:(MKMapPoint)aMapPoint
{
    return _PointForMapPoint(aMapPoint, [_overlay boundingMapRect], _contentScaleFactor);
}

- (CGRect)rectForMapRect:(MKMapRect)aMapRect
{
    var boundingMapRect = [_overlay boundingMapRect];

    return CGRectMake((MKMapRectGetMinX(aMapRect) - MKMapRectGetMinX(boundingMapRect)) * _contentScaleFactor, (MKMapRectGetMinY(aMapRect) - MKMapRectGetMinY(boundingMapRect)) * _contentScaleFactor, MKMapRectGetWidth(aMapRect) * _contentScaleFactor, MKMapRectGetHeight(aMapRect) * _contentScaleFactor);
}

@end

var _PointForMapPoint = function(aMapPoint, aBoundingMapRect, aScale)
{
    var originPoint = aBoundingMapRect.origin;

    return CGPointMake((aMapPoint.x - originPoint.x) * aScale, (aMapPoint.y - originPoint.y) * aScale);
};


var OverlayContainer = function(aMapView, boundingMapRect, drawInMapHandler)
{
    // We define a property to hold the image's
    // div. We'll actually create this div
    // upon receipt of the add() method so we'll
    // leave it null for now.
    this._div = null;
    this._canvas = null;
    this.bounds = LatLngBoundsFromMKCoordinateRegion(MKCoordinateRegionForMapRect(boundingMapRect));
    this.boundingWidth = MKMapRectGetWidth(boundingMapRect);
    this.drawInMap = drawInMapHandler;

    this.setMap(aMapView._map);

    return this;
};

// DEBUG
/*
function get_random_color() {
    var letters = '0123456789ABCDEF'.split('');
    var color = '#';
    for (var i = 0; i < 6; i++ ) {
        color += letters[Math.round(Math.random() * 15)];
    }
    return color;
}
*/
