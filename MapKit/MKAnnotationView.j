@import <AppKit/CPView.j>
@import "MKGeometry.j"

@global google;

@implementation MKAnnotationView : CPView
{
	BOOL        _enabled         @accessors(readonly, getter=isEnabled);
	BOOL        _highlighted     @accessors(readonly, getter=isHighlighted);
	BOOL        _selected        @accessors(readonly, getter=isSelected);
	BOOL        _canShowCallout  @accessors(property=canShowCallout);
	BOOL        _draggable       @accessors(readonly, getter=isDraggable);

	CPImage     _image                     @accessors(property=image);
	CPView      _leftCalloutAccessoryView  @accessors;
	CPView      _rightCalloutAccessoryView @accessors;
	CPString    _reuseIdentifier           @accessors(readonly, getter=reuseIdentifier);
	CGPoint     _calloutOffset             @accessors(property=calloutOffset);
	CGPoint     _centerOffset              @accessors(property=centerOffset);

	id          _annotation                @accessors(readonly, getter=annotation);
	Object      _marker;
	Object      _overlay;
	Object      _infoWindow;
	//TODO : Dragstate
}

+ (void)initialize
{
    GMOverlay.prototype = new google.maps.OverlayView();

    GMOverlay.prototype.onAdd = function()
    {
        console.log("onAdd" + this.toString());
        // We add an overlay to a map via one of the map's panes.
        // We'll add this overlay to the overlayImage pane.
        var panes = this.getPanes();
        panes.overlayMouseTarget.appendChild(this.domElement);
    };

    GMOverlay.prototype.onRemove = function() {
        this.domElement.parentNode.removeChild(this.domElement);
        this.domElement = null;
    };

    GMOverlay.prototype.draw = function()
    {
        console.log("draw" + this.toString());
        // Size and position the overlay. We use a southwest and northeast
        // position of the overlay to peg it to the correct position and size.
        // We need to retrieve the projection from this overlay to do this.
        var overlayProjection = this.getProjection();

        // Retrieve the southwest and northeast coordinates of this overlay
        // in latlngs and convert them to pixels coordinates.
        // We'll use these coordinates to resize the DIV.
        var latLng = LatLngFromCLLocationCoordinate2D(this.coordinate);
        var pos = overlayProjection.fromLatLngToDivPixel(latLng);

        // Resize the image's DIV to fit the indicated dimensions.
        var offset = this.offset;
        var domElement = this.domElement;
        domElement.style.left = (pos.x + offset.x) + 'px';
        domElement.style.top = (pos.y + offset.y) + 'px';
    };
}

- (id)initWithAnnotation:(id)aAnnotation reuseIdentifier:(CPString)anIdentfier
{
    self = [super initWithFrame:CGRectMakeZero()];

	if (self)
	{
        _annotation = aAnnotation;
		_reuseIdentifier = anIdentfier;
		_centerOffset = CGPointMake(0, 0);
		_calloutOffset = CGPointMake(0, 0);
		_draggable = NO;
		_canShowCallout = NO;
		_leftCalloutAccessoryView = nil;
		_rightCalloutAccessoryView = nil;
		_enabled = YES;
		_selected = NO;
		_image = nil;
		_marker = nil;
		_overlay = nil;
		_infoWindow = nil;
	}

	return self;
}

- (void)setAnnotation:(id)anAnnotation
{
    if (anAnnotation !== _annotation)
    {
        _annotation = anAnnotation;
        _marker.setPosition([anAnnotation coordinate]);
        _marker.setTitle([anAnnotation title]);
    }
}

- (void)_updateMarkerAndOverlayForMap:(id)aMap
{
    if (!_marker)
    {
        _marker = new google.maps.Marker({
            position: LatLngFromCLLocationCoordinate2D([_annotation coordinate]),
            clickable:_enabled,
            title:[_annotation title]
        });

        if (_image)
        {
            var size = [_image size];
            var icon = {
                url:[_image filename],
                anchor:{x:_centerOffset.x, y:_centerOffset.y},
                size:{width:size.width, height:size.height}
            };

            _marker.setIcon(icon);
            //_marker.setShape({type:'rect', coord:[0,0,size.width,size.height]});
        }
        else
        {
            _overlay = new GMOverlay(self._DOMElement, [_annotation coordinate], _centerOffset);
            _marker.setVisible(false);
            [self setNeedsDisplay:YES];
        }

        var event = google.maps.event;

        if (_draggable)
        {
            event.addListener(_marker, "dragend", function(mouseEvent)
            {
                var latLng = mouseEvent.latLng;
                [_annotation setCoordinate:CLLocationCoordinate2DFromLatLng(latLng)];
                console.log("drag end" + [_annotation coordinate]);
            });
        }

        if (_enabled)
        {
            event.addListener(_marker, 'click', function()
            {
                [self setSelected:YES animated:YES];
            });
        }
    }

    _marker.setMap(aMap);

    if (_overlay)
        _overlay.setMap(aMap);
}

- (Object)_infoWindow
{
    if (!_infoWindow)
    {
        var title = [_annotation title],
            subtitle = [_annotation subtitle],
            titleHTML = title ? '<div style = "font-weight:bold; font-size:12px">' + title + '</div>' : '',
            subtitleHTML = subtitle ? '<div style = "color:gray; font-size:12px">' + subtitle + '</div>' : '';

        _infoWindow = new google.maps.InfoWindow({
            content: '<div style="">' + titleHTML + subtitleHTML + '</div>'
        });
    }

    return _infoWindow;
}

- (void)_removeMarker
{
    if (_infoWindow)
    {
        _infoWindow.close();
        _infoWindow = nil;
    }

    _marker.setMap(null);

    if (_overlay)
        _overlay.setMap(null);
}

- (void)prepareForReuse
{
    [self _removeMarker];
    _annotation = nil;
}

- (void)setSelected:(BOOL)shouldSelect
{
    [self setSelected:shouldSelect animated:NO];
}

- (void)setSelected:(BOOL)shouldSelect animated:(BOOL)animated
{
    var infoWindow = [self _infoWindow];

    if (shouldSelect)
        infoWindow.open(_marker.getMap(), _marker);
    else
        infoWindow.close();

    _selected = shouldSelect;
}

/*
- (void)setDragState:(MKAnnotationViewDragState)newDragState animated:(BOOL)animated
{

}*/

@end

var GMOverlay = function (domElement, coordinate, offset)
{
  // We define a property to hold the image's
  // div. We'll actually create this div
  // upon receipt of the add() method so we'll
  // leave it null for now.
  this.domElement = domElement;
  this.coordinate = coordinate;
  this.offset = offset;

  return this;
};
