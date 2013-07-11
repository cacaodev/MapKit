
@import <AppKit/CPView.j>

@global google;

@implementation MKAnnotationView : CPView
{
	BOOL        enabled         @accessors(readonly, getter=isEnabled);
	BOOL        highlighted     @accessors(readonly, getter=isHighlighted);
	BOOL        selected        @accessors(readonly, getter=isSelected);
	BOOL        canShowCallout  @accessors;
	BOOL        draggable       @accessors(readonly, getter=isDraggable);

	CPImage     _image                    @accessors(property=image);
	CPView      leftCalloutAccessoryView  @accessors;
	CPView      rightCalloutAccessoryView @accessors;
	CPString    reuseIdentifier           @accessors(readonly);
	CPPoint     calloutOffset             @accessors;
	CPPoint     centerOffset              @accessors;

	id          annotation                @accessors(readonly);
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

- (id)initWithAnnotation:(MKAnnotation)aAnnotation reuseIdentifier:(CPString)anIdentfier
{
    self = [super initWithFrame:CGRectMake(0, 0, 64, 78)];

	if (self)
	{
        annotation = aAnnotation;
		reuseIdentifier = anIdentfier;
		centerOffset = CGPointMake(0,0);
		calloutOffset = CGPointMake(0,0);
		draggable = NO;
		canShowCallout = NO;
		leftCalloutAccessoryView = nil;
		rightCalloutAccessoryView = nil;
		enabled = YES;
		_image = nil;
		_marker = nil;
		_overlay = nil;
		_infoWindow = nil;
	}

	return self;
}

- (void)_updateMarkerAndOverlayForMap:(id)aMap
{
    if (!_marker)
    {
        _marker = new google.maps.Marker({
            position: LatLngFromCLLocationCoordinate2D([annotation coordinate]),
            //draggable:draggable,
            clickable:enabled,
            //anchorPoint:calloutOffset,
            title:[annotation title],
            animation:google.maps.Animation.DROP
        });

        if (_image)
        {
            var size = [_image size];
            var icon = {
                url:[_image filename],
                anchor:{x:centerOffset.x, y:centerOffset.y},
                size:{width:size.width, height:size.height}
            };

            _marker.setIcon(icon);
            //_marker.setShape({type:'rect', coord:[0,0,size.width,size.height]});
        }
        else
        {
            _overlay = new GMOverlay(self._DOMElement, [annotation coordinate], centerOffset);
            _marker.setVisible(false);
            [self setNeedsDisplay:YES];
        }

        var event = google.maps.event;

        if (draggable)
        {
            event.addListener(_marker, "dragend", function(mouseEvent)
            {
                var latLng = mouseEvent.latLng;
                [annotation setCoordinate:CLLocationCoordinate2DFromLatLng(latLng)];
                console.log("drag end" + [annotation coordinate]);
            });
        }

        if (enabled)
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
        var title = [annotation title],
            subtitle = [annotation subtitle],
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
    _marker.setMap(null);
    _marker = nil;

    if (_overlay)
    {
        _overlay.onRemove();
        _overlay = nil;
    }

    if (_infoWindow)
    {
        _infoWindow.close();
        _infoWindow = nil;
    }
}

- (void)prepareForReuse
{

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

    selected = shouldSelect;
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
};