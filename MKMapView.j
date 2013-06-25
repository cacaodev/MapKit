// MKMapView.j
// MapKit
//
// Created by Francisco Tolmasky.
// Copyright (c) 2010 280 North, Inc.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

@import <AppKit/CPView.j>

@import "MKGeometry.j"
@import "MKTypes.j"
@import "ScriptLoader.j"
@import "quadtree.js"

@class MKAnnotation;
@class MKPinAnnotationView;

@global google;
@global GOOGLE_MAPS_PROJECTION;

var _GoogleAPIScriptLoader = nil,
    GOOGLE_API_URL = "http://maps.google.com/maps/api/js?sensor=false&callback=_GoogleMapsLoaded",
    GOOGLE_API_CALLBACK = "_GoogleMapsLoaded",
    MAP_TYPES = ["roadmap", "hybrid", "satellite", "terrain"];

var delegate_mapView_didAddAnnotationViews      = 1 << 1,
    delegate_mapView_didDeselectAnnotationView  = 1 << 2,
    delegate_mapView_didSelectAnnotationView    = 1 << 3,
    delegate_mapView_regionWillChangeAnimated   = 1 << 4,
    delegate_mapView_regionDidChangeAnimated    = 1 << 6,
    delegate_mapView_didAddOverlayRenderers     = 1 << 7,
    delegate_mapView_rendererForOverlay         = 1 << 8,
    delegate_mapView_viewForAnnotation          = 1 << 9,
    delegate_mapViewWillStartLoadingMap         = 1 << 10,
    delegate_mapViewDidFinishLoadingMap         = 1 << 11,
    delegate_mapViewWillStartRenderingMap       = 1 << 12,
    delegate_mapViewDidFinishRenderingMap_fullyRendered = 1 << 13;

@implementation MKMapView : CPView
{
    @outlet                 id _delegate @accessors(getter=delegate);

    MKMapType               _mapType;
    MKCoordinateRegion      _region;
    BOOL                    _scrollEnabled;
    BOOL                    _showsZoomControls;
    BOOL                    delegateDidSendFinishLoading;

    // Tracking
    //BOOL                    _previousTrackingLocation;

   	DOMElement              _DOMMapElement;
	Object                  _map;

    CPArray                 _annotations @accessors(getter=annotations);
    CPArray                 _selectedAnnotations @accessors(getter=selectedAnnotations);
    CPDictionary            _reusableAnnotationViews;
    CPDictionary            markerDictionary;
    MapOptions              _options @accessors(property=options);
    Object                  _quadTree;
    unsigned int            _MKMapViewDelegateMethods;
    Object                  _viewForAnnotationMap;
}

+ (void)initialize
{
	[self exposeBinding:CPValueBinding];
}

+ (Class)_binderClassForBinding:(CPString)theBinding
{
    if (theBinding === CPValueBinding)
        return [_CPValueBinder class];

    return [super _binderClassForBinding:theBinding];
}

+ (CPSet)keyPathsForValuesAffectingCenterCoordinate
{
    return [CPSet setWithObjects:@"region"];
}

+ (CPSet)keyPathsForValuesAffectingVisibleMapRect
{
    return [CPSet setWithObjects:@"region"];
}

+ (id)GoogleAPIScriptLoader
{
    if (!_GoogleAPIScriptLoader)
        _GoogleAPIScriptLoader = [ScriptLoader scriptWithURL:GOOGLE_API_URL callbackParameter:GOOGLE_API_CALLBACK];

    return _GoogleAPIScriptLoader;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _mapType = MKMapTypeStandard;
        _scrollEnabled = YES;
        _showsZoomControls = NO;

        [self _init];

        [self loadGoogleAPI];
    }

    return self;
}

- (void)_init
{
    [self setBackgroundColor:[CPColor colorWithRed:229.0 / 255.0 green:227.0 / 255.0 blue:223.0 / 255.0 alpha:1.0]];

    _region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(43.9267106305051, 8.42626953125), MKCoordinateSpanMake(18.136124269855493, 35.947265625));

    _annotations = [];
    _selectedAnnotations = [];
    _viewForAnnotationMap = {};
    _reusableAnnotationViews = @{};
    markerDictionary = @{};
    delegateDidSendFinishLoading = NO;
    _options = [[MapOptions alloc] init];
    _quadTree = nil;
    _MKMapViewDelegateMethods = 0;
}

- (id)loadGoogleAPI
{
    var loader = [[self class] GoogleAPIScriptLoader];

    if ([[loader operation] isFinished])
        [self _buildMap];
    else
    {
        [loader addCompletionFunction:function()
        {
            [self _buildMap];
        }];

        [loader load];
    }
}

- (void)_buildMap
{
    google.maps.visualRefresh = true;

    var options = {
        center: LatLngFromCLLocationCoordinate2D(_region.center),
        zoom:4,
        mapTypeId:MAP_TYPES[_mapType],
        scrollwheel:_scrollEnabled,
        zoomControl:_showsZoomControls,
        mapTypeControl:false,
        streetViewControl:false
    }

    var contentView = [[CPView alloc] initWithFrame:[self bounds]];
    [contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [self addSubview:contentView];

    _DOMMapElement = contentView._DOMElement;
    _map = new google.maps.Map(_DOMMapElement, options);

    [_options setMapObject:_map];

    [self _sendDidFinishLoadingNotificationIfNeeded];
    [self layoutSubviews];

    var event = google.maps.event;

    event.addListener(_map, "bounds_changed", function()
    {
        [self willChangeValueForKey:"region"];
        _region = [self _getRegion];
        [self didChangeValueForKey:"region"];

        if (_MKMapViewDelegateMethods & delegate_mapView_regionDidChangeAnimated)
            [_delegate mapView:self regionDidChangeAnimated:NO];

        CPLog.debug("bounds_changed");
    });

    event.addListener(_map, "maptypeid_changed", function()
    {
        [self willChangeValueForKey:"mapType"];
        _mapType = MAP_TYPES.indexOf(_map.getMapTypeId());
        [self didChangeValueForKey:"mapType"];
    });

    event.addListener(_map, "tilesloaded", function()
    {
        if (_MKMapViewDelegateMethods & delegate_mapViewDidFinishRenderingMap_fullyRendered)
            [_delegate mapViewDidFinishRenderingMap:self fullyRendered:YES];
    });

    event.addListener(_map, "projection_changed", function()
    {
        GOOGLE_MAPS_PROJECTION = _map.getProjection();
        CPLog.debug("projection_changed");
    });
}

- (void)awakeFromCib
{
    // Try to send the delegate message now if the map loaded before the delegate was decoded.
    [self _sendDidFinishLoadingNotificationIfNeeded];
}

- (void)_sendDidFinishLoadingNotificationIfNeeded
{
    if (!_map || delegateDidSendFinishLoading)
        return;

    if (_MKMapViewDelegateMethods & delegate_mapViewDidFinishLoadingMap)
    {
        [_delegate mapViewDidFinishLoadingMap:self];
        delegateDidSendFinishLoading = YES;
    }
}

- (void)setDelegate:(id)aDelegate
{
    if ([aDelegate respondsToSelector:@selector(mapView:didAddAnnotationViews:)])
        _MKMapViewDelegateMethods |= delegate_mapView_didAddAnnotationViews;

    if ([aDelegate respondsToSelector:@selector(mapView:didDeselectAnnotationView:)])
        _MKMapViewDelegateMethods |= delegate_mapView_didDeselectAnnotationView;

    if ([aDelegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)])
        _MKMapViewDelegateMethods |= delegate_mapView_didSelectAnnotationView;

    if ([aDelegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)])
        _MKMapViewDelegateMethods |= delegate_mapView_regionWillChangeAnimated;

    if ([aDelegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)])
        _MKMapViewDelegateMethods |= delegate_mapView_regionDidChangeAnimated;

    if ([aDelegate respondsToSelector:@selector(mapView:didAddOverlayRenderers:)])
        _MKMapViewDelegateMethods |= delegate_mapView_didAddOverlayRenderers;

    if ([aDelegate respondsToSelector:@selector(mapView:rendererForOverlay:)])
        _MKMapViewDelegateMethods |= delegate_mapView_rendererForOverlay;

    if ([aDelegate respondsToSelector:@selector(mapView:viewForAnnotation:)])
        _MKMapViewDelegateMethods |= delegate_mapView_viewForAnnotation;

    if ([aDelegate respondsToSelector:@selector(mapViewWillStartLoadingMap:)])
        _MKMapViewDelegateMethods |= delegate_mapViewWillStartLoadingMap;

    if ([aDelegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)])
        _MKMapViewDelegateMethods |= delegate_mapViewDidFinishLoadingMap;

    if ([aDelegate respondsToSelector:@selector(mapViewWillStartRenderingMap:)])
        _MKMapViewDelegateMethods |= delegate_mapViewWillStartRenderingMap;

    if ([aDelegate respondsToSelector:@selector(mapViewDidFinishRenderingMap:fullyRendered:)])
        _MKMapViewDelegateMethods |= delegate_mapViewDidFinishRenderingMap_fullyRendered;

    _delegate = aDelegate;
}

- (Object)namespace
{
    return _map;
}

- (MKCoordinateRegion)_getRegion
{
    return MKCoordinateRegionFromLatLngBounds(_map.getBounds());
}

- (MKCoordinateRegion)region
{
    return _region;
}

- (void)setRegion:(MKCoordinateRegion)aRegion
{
    if (_map)
        _map.fitBounds(LatLngBoundsFromMKCoordinateRegion(aRegion));
}

- (MKMapRect)visibleMapRect
{
    return MKMapRectForCoordinateRegion([self region]);
}

- (void)setVisibleMapRect:(MKMapRect)aMapRect
{
    [self setRegion:MKCoordinateRegionForMapRect(aMapRect)];
}

- (CLLocationCoordinate2D)centerCoordinate
{
    return _region.center;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    if (_map)
        _map.setCenter(LatLngFromCLLocationCoordinate2D(aCoordinate));
}

- (float)zoomLevel
{
    return [_options valueForKey:@"zoom"];
}

- (void)setZoomLevel:(float)aZoomLevel
{
    [_options setValue:aZoomLevel forKey:@"zoom"];
}

- (void)setMapType:(MKMapType)aMapType
{
    _mapType = aMapType;

    if (_map)
        _map.setMapTypeId(MAP_TYPES[_mapType]);
}

- (MKMapType)mapType
{
    return _mapType;
}

- (void)setScrollEnabled:(BOOL)shouldBeEnabled
{
    [_options setValue:shouldBeEnabled forKey:@"scrollwheel"];
}

- (BOOL)scrollEnabled
{
    return [_options valueForKey:@"scrollwheel"];
}

- (BOOL)showsZoomControls
{
    return [_options valueForKey:@"zoomControl"];
}

- (void)setShowsZoomControls:(BOOL)shouldShow
{
    [_options setValue:shouldShow forKey:@"zoomControl"];
}

- (void)setOptions:(CPDictionary)opts
{
    [_options _setOptionsFromDictionary:opts];
}

- (void)setSelectedAnnotations:(CPArray)annotations
{
    [_selectedAnnotations enumerateObjectsUsingBlock:function(annotation, idx, stop)
    {
        var view = [self viewForAnnotation:annotation];
        [view setSelected:NO animated:NO];
    }];

    [annotations enumerateObjectsUsingBlock:function(annotation, idx, stop)
    {
        var view = [self viewForAnnotation:annotation];
        [view setSelected:YES animated:YES];
    }];

    _selectedAnnotations = annotations;
}

- (void)setSelectedAnnotation:(id <MKAnnotation>)annotation animated:(BOOL)animated
{
    [self setSelectedAnnotations:[CPArray arrayWithObject:annotation]];
}

/*
    Annotating the Map
*/
- (void)addAnnotation:(id <MKAnnotation>)annotation
{
	[self addAnnotations:[CPArray arrayWithObject:annotation]];
}

- (void)addAnnotations:(CPArray)anAnnotationArray
{
    if (_map)
        [self _addAnnotations:anAnnotationArray];
    else
    {
        var invocation = [[CPInvocation alloc] initWithMethodSignature:nil];
        [invocation setTarget:self];
        [invocation setSelector:@selector(_addAnnotations:)];
        [invocation setArgument:anAnnotationArray atIndex:2];

        var loader = [MKMapView GoogleAPIScriptLoader];
        [loader invoqueWhenLoaded:invocation ignoreMultiple:NO];
    }
}

- (void)_addAnnotations:(CPArray)aAnnotationArray
{
	var annotationsCount = [aAnnotationArray count],
	    quad_nodes = [];

	for (var i = 0; i < annotationsCount; i++)
	{
		var annotation = aAnnotationArray[i],
		    point = MKMapPointForCoordinate([annotation coordinate]),
		    annotationView = [self _dequeueViewForAnnotation:annotation];

        [annotationView _updateMarkerAndOverlayForMap:_map];
		[_annotations addObject:annotation];
		_viewForAnnotationMap[[annotation UID]] = annotationView;

		quad_nodes.push({annotation:annotation, x:point.x, y:point.y});
	}

    if (!_quadTree)
    {
        var world = MKMapRectWorld();
        _quadTree = QUAD.init({x:MKMapRectGetMinX(world), y:MKMapRectGetMinY(world), w:MKMapRectGetWidth(world), h:MKMapRectGetHeight(world)});
    }

    _quadTree.insert(quad_nodes);
}

- (MKAnnotationView)_dequeueViewForAnnotation:(id <MKAnnotation>)annotation
{
    var view = [self viewForAnnotation:annotation];

    if (view)
        return view;

    if (_delegate && (_MKMapViewDelegateMethods & delegate_mapView_viewForAnnotation))
    {
        return [_delegate mapView:self viewForAnnotation:annotation];
    }

    return [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
}

- (void)removeAnnotation:(id <MKAnnotation>)annotation
{
	[self removeAnnotations:[CPArray arrayWithObject:annotation]];
}

- (void)removeAnnotations:(CPArray)aAnnotationArray
{
    [_annotations removeObjectsInArray:aAnnotationArray];
}

/*
    Returns the annotation view associated with the specified annotation object, if any.
    @param annotation The annotation object whose view you want.
    @returns The annotation view or nil if the view has not yet been created. This method may also return nil if the annotation is not in the visible map region and therefore does not have an associated annotation view.
*/
- (MKAnnotationView)viewForAnnotation:(id <MKAnnotation>)anAnnotation
{
    return _viewForAnnotationMap[[anAnnotation UID]];
}

/*
    Returns the annotation objects located in the specified map rectangle.
    @param mapRect The portion of the map that you want to search for annotations.
    @returns The set of annotation objects located in mapRect.
    @discussion This method offers a fast way to retrieve the annotation objects in a particular portion of the map. This method is much faster than doing a linear search of the objects in the annotations property yourself.
*/
- (CPSet)annotationsInMapRect:(MKMapRect)mapRect
{
    var result = [CPSet set];

    if ([_annotations count] == 0)
        return result;

    var origin = mapRect.origin,
        size = mapRect.size,
        quad_rect = {x:origin.x, y:origin.y, w:size.width, h:size.height};

    _quadTree.retrieve(quad_rect, function(item)
    {
        if (MKMapRectContainsPoint(mapRect, item))
            [result addObject:item.annotation];
    });

    return result;
}

/*
    Sets the visible region so that the map displays the specified annotations.
    @param annotations The annotations that you want to be visible in the map.
    @param animated YES if you want the map region change to be animated, or NO if you want the map to display the new region immediately without animations.
*/
- (void)showAnnotations:(CPArray)annotations animated:(BOOL)animated
{
    if ([annotations count] == 0)
        return;

    var mapRect = [self _mapRectForAnnotations:annotations];

    [self setVisibleMapRect:mapRect];
}

- (MKMapRect)_mapRectForAnnotations:(CPArray)annotations
{
    var count = [annotations count],
        result;

    if (count == 0)
        return MKMapRectZero();

    var coordinate = [[annotations objectAtIndex:0] coordinate],
        mapPoint = MKMapPointForCoordinate(coordinate);

    if (count == 1)
    {
        var region = MKCoordinateRegionCopy(_region);
        region.center = coordinate;

        result = MKMapRectForCoordinateRegion(region);
    }
    else
    {
        var minX = mapPoint.x,
            maxX = minX,
            minY = mapPoint.y,
            maxY = minY;

        for (var i = 1; i < count; i++)
        {
            var annotation = annotations[i],
                coord = [annotation coordinate],
                point = MKMapPointForCoordinate(coord),
                x = point.x,
                y = point.y;

                if (x < minX)
                    minX = x;
                else if (x > maxX)
                    maxX = x;

                if (y < minY)
                    minY = y;
                else if (y > maxY)
                    maxY = y;
        }

        result = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
    }

    return result;
}

/*
    Returns The visible rectangle where annotation views are currently being displayed.
*/
- (CGRect)annotationVisibleRect
{
}

/*
    Returns a reusable annotation view located by its identifier.
    @param identifier A string identifying the annotation view to be reused. This string is the same one you specify when initializing the annotation view using the initWithAnnotation:reuseIdentifier: method.
    @returns An annotation view with the specified identifier, or nil if no such object exists in the reuse queue.
    @discussion For performance reasons, you should generally reuse MKAnnotationView objects in your map views. As annotation views move offscreen, the map view moves them to an internally managed reuse queue. As new annotations move onscreen, and your code is prompted to provide a corresponding annotation view, you should always attempt to dequeue an existing view before creating a new one. Dequeueing saves time and memory during performance-critical operations such as scrolling.
*/
- (MKAnnotationView)dequeueReusableAnnotationViewWithIdentifier:(CPString)identifier
{
}

- (void)layoutSubviews
{
    if (_map)
	   google.maps.event.trigger(_map, 'resize');
}

@end

var MKMapTypeKey            = @"MKMapType",
    MKScroolEnabledKey      = @"MKScroolEnabled";

@implementation MKMapView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self setMapType:[aCoder decodeObjectForKey:MKMapTypeKey]];
        [self setScroolEnabled:[aCoder decodeBoolForKey:MKScroolEnabledKey]];

        [self _init];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:[self mapType] forKey:MKMapTypeKey];
    [aCoder encodeBool:[self scrollEnabled] forKey:MKScroolEnabledKey];
}

@end

@implementation MapOptions: CPObject
{
    Object          mapObject @accessors;
    CPDictionary    options;
}

- (id)init
{
    self = [super init];
    options = [CPDictionary dictionary];
    return self;
}

- (void)setMapObject:(Object)aMapObject // Call only once when the gmap is loaded
{
    mapObject = aMapObject;
    [self _setOptionsFromDictionary:options];
}

- (void)_setOptionsFromDictionary:(CPDictionary)opts
{
    var keys = [opts allKeys];
    if ([keys count] == 0)
        return;

    var js_options = {};
    [keys enumerateObjectsUsingBlock:function(key, idx)
    {
        var value = [opts objectForKey:key];
        js_options[key] = value;
        [options setObject:value forKey:key]; // Will send KVO notifications for each value
    }];

    if (mapObject != null)
        mapObject.setOptions(js_options);
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var dict = [CPDictionary dictionaryWithObject:aValue forKey:aKey];
    [self _setOptionsFromDictionary:dict];
}

- (id)valueForKey:(CPString)aKey
{
    return [options objectForKey:aKey];
}

@end
