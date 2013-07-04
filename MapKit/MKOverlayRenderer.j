@implementation MKOverlayRenderer : CPObject
{
    id        _overlay            @accessors(getter=overlay);
    float     _alpha              @accessors(property=alpha);
    float     _contentScaleFactor @accessors(setter=_setContentScaleFactor:);
    BOOL      _needsDisplay;
    BOOL      _needsLayout;
    Object    _overlayView;
}
/*
+ (void)initialize
{
    _initOverlayContainer();
}
*/
- (id)initWithOverlay:(id)anOverlay
{
    self = [super init];

    _overlay = anOverlay;
    _alpha = 1.0;
    _contentScaleFactor = 0;
    _needsDisplay = YES;
    _needsLayout = YES;
    _overlayView = nil;
    _initOverlayContainer();
    
    return self;
}

- (void)_setContentScaleFactor:(float)zoomLevel
{
    if (zoomLevel !== _contentScaleFactor)
    {
        _contentScaleFactor = zoomLevel;
        _needsLayout = YES;
        _needsDisplay = YES;
    }
}

- (void)_remove
{
    _overlayView.setMap(null);
}

- (void)_drawMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale inMap:(MKMapView)aMapView
{
    if (!_overlayView)
    {
        var bounds = LatLngBoundsFromMKCoordinateRegion(MKCoordinateRegionForMapRect([_overlay boundingMapRect]));
        _overlayView = new OverlayContainer(aMapView, bounds, function()
        {
            CPLog.debug("ON ADD HANDLER");
            _overlayView.layout();
            [self _drawMapRect:mapRect zoomScale:zoomScale];
        });
        
        _needsLayout = NO;
        _needsDisplay = NO;        
    }

    [self layoutIfNeeded];
    [self displayIfNeededInMapRect:mapRect zoomScale:zoomScale];
}

- (void)layoutIfNeeded
{
    if (_needsLayout)
    {
        _overlayView.layout();
        _needsLayout = NO;
    }
}

- (void)displayIfNeededInMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale
{
    if (_needsDisplay)
    {
        [self _drawMapRect:mapRect zoomScale:zoomScale];
        _needsDisplay = NO;
    }
}

- (void)_drawMapRect:(MKMapRect)mapRect zoomScale:(float)zoomScale
{
    var context = _overlayView.canvas.getContext("2d");
    [self drawMapRect:mapRect zoomScale:zoomScale inContext:context];  
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

- (CGPoint)convertMapPoint:(MKMapPoint)aMapPoint
{
    var boundingMapRect = [_overlay boundingMapRect];
    
    return _PointForMapPoint(aMapPoint, boundingMapRect, 1.0);
}

- (CGPoint)pointForMapPoint:(MKMapPoint)aMapPoint
{
    var boundingMapRect = [_overlay boundingMapRect];

    return _PointForMapPoint(aMapPoint, boundingMapRect, _contentScaleFactor);
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

function OverlayContainer(mapView, bounds, onadd)
{
  // We define a property to hold the image's
  // div. We'll actually create this div
  // upon receipt of the add() method so we'll
  // leave it null for now.
  this.div = null;
  this.canvas = null;
  this.mapView = mapView;
  this.bounds = bounds;
  this.onadd = onadd;
  
  this.setMap(mapView._map);
  
  return this;
}

var _initOverlayContainer = function()
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
      //div.style.backgroundColor = "red";
      
      var canvas = document.createElement('canvas');
      div.appendChild(canvas);
      // Set the overlay's div_ property to this DIV
      this.div = div;
      this.canvas = canvas;
    
      // We add an overlay to a map via one of the map's panes.
      // We'll add this overlay to the overlayImage pane.
      var panes = this.getPanes();
      panes.overlayLayer.appendChild(div);
      
      this.onadd();
    };
    
    OverlayContainer.prototype.onRemove = function() {
        this.div.parentNode.removeChild(this.div);
        this.div = null;
        this.canvas = null;
    };
    
    OverlayContainer.prototype.layout = function()
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
      var style = this.div.style,
          width = ne.x - sw.x,
          height = sw.y - ne.y;
    
      style.left = sw.x + "px";
      style.top = ne.y + "px";
      style.width  = width + "px" ;
      style.height = height + "px";
      
      var canvas = this.canvas;
      canvas.width = width;
      canvas.height = height;
    };
    
    OverlayContainer.prototype.draw = function()
    {
        console.log("GOOGLE MAPS WANTS TO DRAW");
    };
};
