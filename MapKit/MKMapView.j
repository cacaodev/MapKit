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
@import <Foundation/CPError.j>

@import "MKGeometry.j"
@import "MKTypes.j"
@import "ScriptLoader.j"
@import "QuadTree.js"

@class MKOverlay
@class MKUserLocation
@class MKPinAnnotationView
@class MKMapType

@global google

#define GOOGLE_API_KEY "YOUR_GOOGLE_API_KEY_HERE"

var _GoogleAPIScriptLoader = nil,
    GOOGLE_API_URL = "http://maps.google.com/maps/api/js?callback=_GoogleMapsLoaded&key=" + GOOGLE_API_KEY,
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
    delegate_mapViewWillStartLocatingUser       = 1 << 13,
    delegate_mapViewDidStopLocatingUser         = 1 << 14,
    delegate_mapView_didFailToLocateUserWithError = 1 << 15,
    delegate_mapViewDidFinishRenderingMap_fullyRendered = 1 << 16;

@protocol MKAnnotation <CPObject>

@optional
- (CLLocationCoordinate2D)coordinate;
- (void)setCoordinate:(CLLocationCoordinate2D)coordinate;
- (CPString)title;
- (CPString)subtitle;

@end

@implementation MKMapView : CPView
{
    @outlet                 id delegate @accessors;

    MKMapType               _mapType;
    MKCoordinateRegion      _region;
    BOOL                    _scrollEnabled;
    BOOL                    _showsZoomControls;
    BOOL                    _delegateDidSendFinishLoading;
    BOOL                    _showsUserLocation @accessors(readonly, getter=showsUserLocation);
    // Tracking
    //BOOL                    _previousTrackingLocation;

   	DOMElement              _DOMMapElement;
	Object                  _map;

    CPArray                 _annotations;
    CPArray                 _selectedAnnotations @accessors(readonly, getter=selectedAnnotations);
    CPDictionary            _reusableAnnotationViews;
    CPArray                 _overlays;
    CPArray                 _visibleOverlays;

    unsigned int            _MKMapViewDelegateMethods;

    Object                  _options @accessors(property=options);

    MKUserLocation          _userLocation @accessors(readonly, getter=userLocation);
    Object                  _annotationsQuadTree;
//  Object                  _overlaysQuadTree;
    Object                  _ViewForAnnotation;
    Map                     _RendererForOverlay;
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
    }

    return self;
}

- (void)viewDidMoveToSuperview
{
    if ([self superview])
        [self loadGoogleAPI];
}

- (void)_init
{
    [self setBackgroundColor:[CPColor colorWithRed:229.0 / 255.0 green:227.0 / 255.0 blue:223.0 / 255.0 alpha:1.0]];

    _region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(46.230469, 2.109375), MKCoordinateSpanMake(17.454362, 40.429673));
    _annotations = [];
    _selectedAnnotations = [];
    _reusableAnnotationViews = @{};
    _overlays = [];
    _visibleOverlays = [];
    _delegateDidSendFinishLoading = NO;
    _options = [[MapOptions alloc] init];
    _annotationsQuadTree = nil;
//    _overlaysQuadTree = nil;
    _MKMapViewDelegateMethods = 0;
    _ViewForAnnotation = {};
    _RendererForOverlay = new Map();
    _showsUserLocation = NO;
    _userLocation = nil;
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
//CPLog.debug(_cmd);

    google.maps.visualRefresh = true;

    var options = {
        center: LatLngFromCLLocationCoordinate2D(_region.center),
        zoom:[self zoomLevel],
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
            [delegate mapView:self regionDidChangeAnimated:NO];
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
            [delegate mapViewDidFinishRenderingMap:self fullyRendered:YES];
    });
}

- (void)awakeFromCib
{
    // Try to send the delegate message now if the map loaded before the delegate was decoded.
    [self _sendDidFinishLoadingNotificationIfNeeded];
}

- (void)_sendDidFinishLoadingNotificationIfNeeded
{
    if (!_map || _delegateDidSendFinishLoading)
        return;

    if (_MKMapViewDelegateMethods & delegate_mapViewDidFinishLoadingMap)
    {
        [delegate mapViewDidFinishLoadingMap:self];
        _delegateDidSendFinishLoading = YES;
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

// TODO: In OSX MapKit this is called every time tiles are loaded ?!!
    if ([aDelegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)])
        _MKMapViewDelegateMethods |= delegate_mapViewDidFinishLoadingMap;

    if ([aDelegate respondsToSelector:@selector(mapViewWillStartRenderingMap:)])
        _MKMapViewDelegateMethods |= delegate_mapViewWillStartRenderingMap;

// TODO: fullyrendered parameter ?
    if ([aDelegate respondsToSelector:@selector(mapViewDidFinishRenderingMap:fullyRendered:)])
        _MKMapViewDelegateMethods |= delegate_mapViewDidFinishRenderingMap_fullyRendered;

    if ([aDelegate respondsToSelector:@selector(mapViewWillStartLocatingUser:)])
        _MKMapViewDelegateMethods |= delegate_mapViewWillStartLocatingUser;

    if ([aDelegate respondsToSelector:@selector(mapViewDidStopLocatingUser:)])
        _MKMapViewDelegateMethods |= delegate_mapViewDidStopLocatingUser;

    if ([aDelegate respondsToSelector:@selector(mapView:didFailToLocateUserWithError:)])
        _MKMapViewDelegateMethods |= delegate_mapView_didFailToLocateUserWithError;

    delegate = aDelegate;
}

- (Object)map
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
        [self _setRegion:aRegion];
    else
    {
        var invocation = [[CPInvocation alloc] initWithMethodSignature:nil];
        [invocation setTarget:self];
        [invocation setSelector:@selector(_setRegion:)];
        [invocation setArgument:aRegion atIndex:2];

        var loader = [MKMapView GoogleAPIScriptLoader];
        [loader invoqueWhenLoaded:invocation ignoreMultiple:NO];
    }
}

- (void)_setRegion:(MKCoordinateRegion)aRegion
{
    _map.fitBounds(LatLngBoundsFromMKCoordinateRegion(aRegion));
}

- (MKMapRect)visibleMapRect
{
    return MKMapRectForCoordinateRegion(_region);
}

- (void)setVisibleMapRect:(MKMapRect)aMapRect
{
    if (_map)
        [self _setVisibleMapRect:aMapRect];
    else
    {
        var invocation = [[CPInvocation alloc] initWithMethodSignature:nil];
        [invocation setTarget:self];
        [invocation setSelector:@selector(_setVisibleMapRect:)];
        [invocation setArgument:aMapRect atIndex:2];

        var loader = [MKMapView GoogleAPIScriptLoader];
        [loader invoqueWhenLoaded:invocation ignoreMultiple:NO];
    }
}

- (void)_setVisibleMapRect:(MKMapRect)aMapRect
{
    [self _setRegion:MKCoordinateRegionForMapRect(aMapRect)];
}

- (CLLocationCoordinate2D)centerCoordinate
{
    return _region.center;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    if (_map)
        [self _setCenterCoordinate:aCoordinate];
    else
    {
        var invocation = [[CPInvocation alloc] initWithMethodSignature:nil];
        [invocation setTarget:self];
        [invocation setSelector:@selector(_setCenterCoordinate:)];
        [invocation setArgument:aCoordinate atIndex:2];

        var loader = [MKMapView GoogleAPIScriptLoader];
        [loader invoqueWhenLoaded:invocation ignoreMultiple:NO];
    }
}

- (void)_setCenterCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    _map.setCenter(LatLngFromCLLocationCoordinate2D(aCoordinate));
}

- (float)zoomScale
{
    return CGRectGetWidth([self bounds]) / MKMapRectGetWidth([self visibleMapRect]);
}

- (CPInteger)zoomLevel
{
    return ROUND(LOG([self zoomScale]) / LN2) + 20;
}

- (void)setZoomLevel:(float)aZoomLevel
{
    [_options setValue:aZoomLevel forKey:@"zoom"];
}

- (void)setMapType:(MKMapType)aMapType
{
    if (_map)
        [self _setMapType:aMapType];
    else
    {
        var invocation = [[CPInvocation alloc] initWithMethodSignature:nil];
        [invocation setTarget:self];
        [invocation setSelector:@selector(_setMapType:)];
        [invocation setArgument:aMapType atIndex:2];

        var loader = [MKMapView GoogleAPIScriptLoader];
        [loader invoqueWhenLoaded:invocation ignoreMultiple:NO];
    }
}

- (void)_setMapType:(MKMapType)aMapType
{
    _mapType = aMapType;
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

- (void)setOptions:(Object)opts
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

- (void)deselectAnnotation:(id <MKAnnotation>)annotation animated:(BOOL)animated
{
    var view = [self viewForAnnotation:annotation];

    if (view)
        [view setSelected:NO animated:NO];

    [_selectedAnnotations removeObject:annotation];
}

/*
    Annotating the Map
*/
- (CPArray)annotations
{
    return [CPArray arrayWithArray:_annotations];
}

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
	[aAnnotationArray enumerateObjectsUsingBlock:function(annotation, idx, stop)
	{
		var annotationView = [self _dequeueViewForAnnotation:annotation],
		    uuid = [annotation UID];

        [annotationView _updateMarkerAndOverlayForMap:_map];
		_ViewForAnnotation[uuid] = annotationView;

		[_annotations addObject:annotation];
	}];

    if (!_annotationsQuadTree)
        _annotationsQuadTree = new QuadTree(MKMapRectWorld(), true);

    [self addAnnotationsToQuadTree:aAnnotationArray];
}

- (MKAnnotationView)_dequeueViewForAnnotation:(id <MKAnnotation>)annotation
{
    var view = [self viewForAnnotation:annotation];

    if (view)
        return view;

    if (delegate && (_MKMapViewDelegateMethods & delegate_mapView_viewForAnnotation))
    {
        return [delegate mapView:self viewForAnnotation:annotation];
    }

    return [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
}

- (void)removeAnnotation:(id <MKAnnotation>)annotation
{
	[self removeAnnotations:[CPArray arrayWithObject:annotation]];
}

- (void)removeAnnotations:(CPArray)aAnnotationArray
{
    var count = [aAnnotationArray count];

    if (count == 0)
        return;

    while (count--)
    {
        var annotation = [aAnnotationArray objectAtIndex:count];

        var view = [self viewForAnnotation:annotation];
        if (view)
        {
            [view _removeMarker];
            delete _ViewForAnnotation[[annotation UID]];
        }

        [_annotations removeObjectIdenticalTo:annotation];
    }

    if (_annotationsQuadTree)
        _annotationsQuadTree.clear();

    [self addAnnotationsToQuadTree:_annotations];
}

/*
    Returns the annotation view associated with the specified annotation object, if any.
    @param annotation The annotation object whose view you want.
    @returns The annotation view or nil if the view has not yet been created. This method may also return nil if the annotation is not in the visible map region and therefore does not have an associated annotation view.
*/
- (MKAnnotationView)viewForAnnotation:(id <MKAnnotation>)anAnnotation
{
    return _ViewForAnnotation[[anAnnotation UID]];
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

    var overlappingNodes = _annotationsQuadTree.retrieve(quad_rect);

    [overlappingNodes enumerateObjectsUsingBlock:function(aNode, idx, stop)
    {
        var p = MKMapPointMake(aNode.x, aNode.y);

        if (MKMapRectContainsPoint(mapRect, p))
            [result addObject:aNode.annotation];
    }];

    return result;
}

/*
    Sets the visible region so that the map displays the specified annotations.
    @param annotations The annotations that you want to be visible in the map.
    @param animated YES if you want the map region change to be animated, or NO if you want the map to display the new region immediately without animations.
*/
- (void)showAnnotations:(CPArray)annotations animated:(BOOL)animated
{
    var count = [annotations count];

    if (count == 0)
        return;
    else if (count == 1)
        [self setCenterCoordinate:[[annotations objectAtIndex:0] coordinate]];
    else
        [self setVisibleMapRect:[self _mapRectForAnnotations:annotations]];
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

        result = MKMapRectForCoordinateRegion(region); // Something wrong here. The scale changes, it should not.
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

// Overlays;

- (CPArray)overlays
{
    return [CPArray arrayWithArray:_overlays];
}

- (void)addOverlay:(id)anOverlay
{
    [self addOverlays:[CPArray arrayWithObject:anOverlay]];
}

- (void)addOverlays:(CPArray)overlays
{
    if (![overlays count])
        return;

//    if (!_overlaysQuadTree)
//        _overlaysQuadTree = new QuadTree(MKMapRectWorld());

    [_overlays addObjectsFromArray:overlays];

    //[self addOverlaysToQuadTree:overlays];

    [overlays enumerateObjectsUsingBlock:function(ov, idx, stop)
    {
        var renderer = [self _rendererForOverlay:ov];
        [renderer _addToMap:self];
    }];
}

- (void)removeOverlay:(id)anOverlay
{
    [self removeOverlays:[CPArray arrayWithObject:anOverlay]];
}

- (void)removeOverlays:(CPArray)overlays
{
    if (![overlays count])
        return;

    [overlays enumerateObjectsUsingBlock:function(ov, idx, stop)
    {
        var renderer = _RendererForOverlay.get(ov);

        if (renderer) {
            [renderer _remove];
            _RendererForOverlay.delete(ov);
        }
    }];

    [_overlays removeObjectsInArray:overlays];
/*
    _overlaysQuadTree.clear();
    [self addOverlaysToQuadTree:_overlays];

    [self _updateOverlays];
*/
}

- (id)_rendererForOverlay:(id)anOverlay
{
    var renderer = _RendererForOverlay.get(anOverlay);

    if (!renderer && (_MKMapViewDelegateMethods & delegate_mapView_rendererForOverlay))
    {
        renderer = [delegate mapView:self rendererForOverlay:anOverlay];
        _RendererForOverlay.set(anOverlay, renderer);
    }

    return renderer;
}

// QUADTREE SUPPORT

- (void)addAnnotationsToQuadTree:(CPArray)annotations
{
    [annotations enumerateObjectsUsingBlock:function(anAnnotation, idx, stop)
    {
        var point = MKMapPointForCoordinate([anAnnotation coordinate]),
            node = {annotation:anAnnotation, x:point.x, y:point.y};

        _annotationsQuadTree.insert(node);
    }];
}
/*
- (void)addOverlaysToQuadTree:(CPArray)overlays
{
    [self insertObjects:overlays inQuadTree:_overlaysQuadTree usingNodeFunction:function(anOverlay)
    {
        var boundingMapRect = [anOverlay boundingMapRect];

        return {overlay:anOverlay,
                      x:MKMapRectGetMinX(boundingMapRect),
                      y:MKMapRectGetMinY(boundingMapRect),
                      width:MKMapRectGetWidth(boundingMapRect),
                      height:MKMapRectGetHeight(boundingMapRect)};
    }];
}

- (void)insertObjects:(CPArray)objects inQuadTree:(Object)aQuadTree usingNodeFunction:(Function)aFunction
{
    var quad_nodes = [];

    [objects enumerateObjectsUsingBlock:function(object, idx, stop)
    {
        var node = aFunction(object);
        quad_nodes.push(node);
    }];

    aQuadTree.insert(quad_nodes);
}

- (void)_updateOverlays
{
    return;

    if (!_overlaysQuadTree)
        return;

    var toRemove           = [CPArray arrayWithArray:_visibleOverlays],
        toAdd              = [CPArray array],
        unchanged          = [CPArray array],
        newVisibleOverlays = [CPArray array],

        visibleMapRect = [self visibleMapRect];

    [self enumerateItemsInMapRect:visibleMapRect usingBlock:function(item)
    {
        var overlay = item.overlay,
            count = [toRemove count],
            found = NO;

        while (count--)
        {
            if (overlay == toRemove[count])
            {
                [toRemove removeObjectAtIndex:count];
                [unchanged addObject:overlay];
                found = YES;

                break;
            }
        }

        if (found == NO)
            [toAdd addObject:overlay];

        [newVisibleOverlays addObject:overlay];
    }];

    //CPLog.debug("REMOVE: " + toRemove + " ADD: " + toAdd + " Unchanged: " + unchanged);

    if ([toAdd count])
    {
        var zoomScale = [self zoomScale];

        [toAdd enumerateObjectsUsingBlock:function(overlay, idx, stop)
        {
            var renderer = [self _rendererForOverlay:overlay];

            if (!renderer)
                return;

            [renderer _setContentScaleFactor:zoomScale];
            [renderer _addToMap:self];
        }];
    }

    if ([unchanged count])
    {
        var mapRect = [self visibleMapRect],
            zoomScale = [self zoomScale];

        [unchanged enumerateObjectsUsingBlock:function(overlay, idx, stop)
        {
            var renderer = [self _rendererForOverlay:overlay];
            [renderer _setContentScaleFactor:zoomScale];
        }];
    }

    [toRemove enumerateObjectsUsingBlock:function(overlay, idx, stop)
    {
        var renderer = [self _rendererForOverlay:overlay];
        [renderer _remove];
    }];

    _visibleOverlays = newVisibleOverlays;
}

- (void)enumerateItemsInMapRect:(MKMapRect)aMapRect usingBlock:(Function)aFunction
{
    var overlappingItems = _overlaysQuadTree.retrieve(aMapRect);

    [overlappingItems enumerateObjectsUsingBlock:function(item, idx, stop)
    {
        var itemMapRect = MKMapRectMake(item.x, item.y, item.width, item.height);

        if (CGRectIntersectsRect(itemMapRect, aMapRect))
            aFunction(item);
    }];
}
*/
// User location
// TODO: track user location. Is it useful on a non-mobile device ?
- (void)setShowsUserLocation:(BOOL)show
{
    if (show === _showsUserLocation)
        return;

    var geolocation = window.navigator.geolocation;

    if (!geolocation)
    {
        if (_MKMapViewDelegateMethods & delegate_mapView_didFailToLocateUserWithError)
        {
            var error = [CPError errorWithDomain:CPCappuccinoErrorDomain code:4 userInfo:@{CPLocalizedDescriptionKey:"This browser does not support geolocation"}];
            [delegate mapView:self didFailToLocateUserWithError:error];
        }
    }
    else if (!show)
    {
        _showsUserLocation = NO;
        _userLocation = nil;

        if (_MKMapViewDelegateMethods & delegate_mapViewDidStopLocatingUser)
            [delegate mapViewDidStopLocatingUser:self];
    }
    else
    {
        _userLocation = [[MKUserLocation alloc] init];
        [_userLocation _setUpdating:YES];

        geolocation.getCurrentPosition(function(aGeoLocation)
        {
            var coords = aGeoLocation.coords,
                location = CLLocationCoordinate2DMake(coords.latitude, coords.longitude);

            [_userLocation _setLocation:location];
            [_userLocation _setAccuracy:coords.accuracy];
            [_userLocation _setHeading:coords.heading];
            [_userLocation setTitle:@"User Location"];
            [_userLocation setSubtitle:CPStringFromCLLocationCoordinate2D(location)];
            [_userLocation _setUpdating:NO];

            _showsUserLocation = YES;

            if (_MKMapViewDelegateMethods & delegate_mapViewWillStartLocatingUser)
                [delegate mapViewWillStartLocatingUser:self];

        }, function(err)
        {
            _userLocation = nil;
            _showsUserLocation = NO;

            if (_MKMapViewDelegateMethods & delegate_mapView_didFailToLocateUserWithError)
            {
                var error = [CPError errorWithDomain:CPCappuccinoErrorDomain code:err.code userInfo:@{CPLocalizedDescriptionKey:err.message}];
                [delegate mapView:self didFailToLocateUserWithError:error];
            }
        });
    }
}

- (BOOL)isUserLocationVisible
{
    if (!_userLocation)
        return NO;

    // TODO: Handle the accuracy around the point
    return MKMapRectContainsPoint([self visibleMapRect], MKMapPointForCoordinate([_userLocation location]));
}

// Pixel / coordinate conversions
- (CLLocationCoordinate2D)convertPoint:(CGPoint)point toCoordinateFromView:(CPView)view
{
    var mapRect = [self visibleMapRect],
        m = MKMapRectGetWidth(mapRect) / CGRectGetWidth([self bounds]);

    var convertedPoint = [self convertPoint:point fromView:view];

    return CLLocationCoordinate2DMake(MKMapRectGetMinX(mapRect) + convertedPoint.x * m, MKMapRectGetMinY(mapRect) + convertedPoint.y * m);
}

- (CGPoint)convertMapPoint:(MKMapPoint)aMapPoint toPointToView:(CPView)view
{
    var mapRect = [self visibleMapRect],
        m = MKMapRectGetWidth(mapRect) / CGRectGetWidth([self bounds]);

    var point = CGPointMake((aMapPoint.x - MKMapRectGetMinX(mapRect)) / m , (aMapPoint.y - MKMapRectGetMinY(mapRect)) / m);

    return [self convertPoint:point toView:view];
}

- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate toPointToView:(CPView)view
{
    var mapPoint = MKMapPointForCoordinate(coordinate);

    return [self convertMapPoint:mapPoint toPointToView:view];
}

- (MKCoordinateRegion)convertRect:(CGRect)rect toRegionFromView:(CPView)view
{
    var mapRect = [self visibleMapRect],
        m = MKMapRectGetWidth(mapRect) / CGRectGetWidth([self bounds]);

    var convertedRect = [self convertRect:rect fromView:view];

    var newMapRect = MKMapRectMake(MKMapRectGetMinX(mapRect) + CGRectGetMinX(convertedRect) * m, MKMapRectGetMinY(mapRect) + CGRectGetMinY(convertedRect) * m, CGRectGetWidth(convertedRect) * m, CGRectGetHeight(convertedRect) * m);

    return MKCoordinateRegionForMapRect(newMapRect);
}

- (CGRect)convertRegion:(MKCoordinateRegion)region toRectToView:(CPView)view
{
    var mapRect = MKMapRectForCoordinateRegion(region);

    return [self convertMapRect:mapRect toRectToView:view];
}

- (CGRect)convertMapRect:(MKMapRect)aMapRect toRectToView:(CPView)view
{
    var visibleMapRect = [self visibleMapRect],
        m = MKMapRectGetWidth(visibleMapRect) / CGRectGetWidth([self bounds]);

    var baseRect = CGRectMake((MKMapRectGetMinX(aMapRect) - MKMapRectGetMinX(visibleMapRect)) / m, (MKMapRectGetMinY(aMapRect) - MKMapRectGetMinY(visibleMapRect)) / m, MKMapRectGetWidth(aMapRect) / m, MKMapRectGetHeight(aMapRect) / m);

    return [self convertRect:baseRect toView:view];
}

- (void)layoutSubviews
{
// TODO: send a bounds_changed event ?
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
