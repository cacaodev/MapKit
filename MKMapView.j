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

var _GoogleAPIScriptLoader = nil,
    GOOGLE_API_URL = "http://maps.google.com/maps/api/js?sensor=false&callback=_GoogleMapsLoaded",
    GOOGLE_API_CALLBACK = "_GoogleMapsLoaded",
    MAP_TYPES = ["roadmap", "hybrid", "satellite", "terrain"];

@implementation MKMapView : CPView
{
    @outlet                 id delegate @accessors;

    CLLocationCoordinate2D  m_centerCoordinate;
    CPInteger               m_zoomLevel;
    MKMapType               m_mapType;
    BOOL                    m_scrollWheelZoomEnabled;

    // Tracking
    //BOOL                    m_previousTrackingLocation;

   	DOMElement              m_DOMMapElement;
	Object                  m_map;

    BOOL                    delegateDidSendFinishLoading;
    CPArray                 annotations @accessors(readonly);
    CPDictionary            markerDictionary;
    MapOptions              m_options @accessors(property=options);
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

+ (CPSet)keyPathsForValuesAffectingCenterCoordinateLatitude
{
    return [CPSet setWithObjects:@"centerCoordinate"];
}

+ (CPSet)keyPathsForValuesAffectingCenterCoordinateLongitude
{
    return [CPSet setWithObjects:@"centerCoordinate"];
}

+ (id)GoogleAPIScriptLoader
{
    if (!_GoogleAPIScriptLoader)
        _GoogleAPIScriptLoader = [ScriptLoader scriptWithURL:GOOGLE_API_URL callbackParameter:GOOGLE_API_CALLBACK];
        
    return _GoogleAPIScriptLoader;
}

- (id)initWithFrame:(CGRect)aFrame
{
    return [self initWithFrame:aFrame centerCoordinate:nil];
}

- (id)initWithFrame:(CGRect)aFrame centerCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    self = [super initWithFrame:aFrame];

    if (self)
    {           
        m_centerCoordinate = aCoordinate || new CLLocationCoordinate2D(52, -1);
        m_zoomLevel = 6;
        m_mapType = MKMapTypeStandard;
        m_scrollWheelZoomEnabled = YES;

        [self _init];
        
        [self loadGoogleAPI];
    }

    return self;
}

- (void)_init
{
    [self setBackgroundColor:[CPColor colorWithRed:229.0 / 255.0 green:227.0 / 255.0 blue:223.0 / 255.0 alpha:1.0]];

    annotations = [CPArray array];
    markerDictionary = [[CPDictionary alloc] init];
    delegateDidSendFinishLoading = NO;
    m_options = [[MapOptions alloc] init];
}

- (id)loadGoogleAPI
{
    var loader = [[self class] GoogleAPIScriptLoader];
    
    if ([[loader operation] isFinished])
        [self _buildMap];
    else
    {        
        var completionFunction = function(){[self _buildMap];};
        [loader addCompletionFunction:completionFunction];
        [loader load];
    }
}

- (void)_buildMap
{
    var options = {
        center:LatLngFromCLLocationCoordinate2D(m_centerCoordinate),
        zoom:m_zoomLevel,
        mapTypeId:MAP_TYPES[m_mapType],
        scrollwheel:m_scrollWheelZoomEnabled
    }
    
    var contentView = [[CPView alloc] initWithFrame:[self bounds]];
    [contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [self addSubview:contentView];
    
    m_DOMMapElement = contentView._DOMElement;
    m_map = new google.maps.Map(m_DOMMapElement, options);
    [m_options setMapObject:m_map];

    [self _sendDidFinishLoadingNotificationIfNeeded];
    [self layoutSubviews];
    
    var event = google.maps.event;
    event.addListener(m_map, "zoom_changed", function()
    {
        [self willChangeValueForKey:"zoomLevel"];
        m_zoomLevel = m_map.getZoom();
        [self didChangeValueForKey:"zoomLevel"];
        CPLogConsole("zoom_changed " + m_zoomLevel);
    });

    event.addListener(m_map, "center_changed", function()
    {
        [self willChangeValueForKey:"centerCoordinate"];
        var latLng = m_map.getCenter();
        m_centerCoordinate = new CLLocationCoordinate2D(latLng.lat(), latLng.lng());
        [self didChangeValueForKey:"centerCoordinate"];
    });

    event.addListener(m_map, "maptypeid_changed", function()
    {
        [self willChangeValueForKey:"mapType"];
        m_mapType = MAP_TYPES.indexOf(m_map.getMapTypeId());
        [self didChangeValueForKey:"mapType"];
    });    
}

- (void)awakeFromCib
{
    // Try to send the delegate message now if the map loaded before the delegate was decoded.
    [self _sendDidFinishLoadingNotificationIfNeeded];
}

- (void)_sendDidFinishLoadingNotificationIfNeeded
{
    if (m_map && !delegateDidSendFinishLoading && delegate && [delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)])
    {
        [delegate mapViewDidFinishLoadingMap:self];
        delegateDidSendFinishLoading = YES;
    }
}

- (Object)namespace
{
    return m_map;
}

- (MKCoordinateRegion)region
{
    if (m_map)
        return MKCoordinateRegionFromLatLngBounds(m_map.getBounds());

    return nil;
}

- (void)setRegion:(MKCoordinateRegion)aRegion
{
    m_region = aRegion;

    if (m_map)
        m_map.fitBounds(LatLngBoundsFromMKCoordinateRegion(aRegion));
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    m_centerCoordinate = aCoordinate;

    if (m_map)
        m_map.setCenter(LatLngFromCLLocationCoordinate2D(aCoordinate));
}

- (CLLocationCoordinate2D)centerCoordinate
{
    return m_centerCoordinate;
}

- (void)setCenterCoordinateLatitude:(float)aLatitude
{
    [self setCenterCoordinate:new CLLocationCoordinate2D(aLatitude, [self centerCoordinateLongitude])];
}

- (float)centerCoordinateLatitude
{
    return [self centerCoordinate].latitude;
}

- (void)setCenterCoordinateLongitude:(float)aLongitude
{
    [self setCenterCoordinate:new CLLocationCoordinate2D([self centerCoordinateLatitude], aLongitude)];
}

- (float)centerCoordinateLongitude
{
    return [self centerCoordinate].longitude;
}

- (void)setZoomLevel:(float)aZoomLevel
{
    m_zoomLevel = +aZoomLevel || 0;

    if (m_map)
        m_map.setZoom(m_zoomLevel);
}

- (int)zoomLevel
{
    return m_zoomLevel;
}

- (void)setMapType:(MKMapType)aMapType
{
    m_mapType = aMapType;

    if (m_map)
        m_map.setMapTypeId(MAP_TYPES[m_mapType]);
}

- (MKMapType)mapType
{
    return m_mapType;
}

- (void)setScrollWheelZoomEnabled:(BOOL)shouldBeEnabled
{
    [m_options setValue:shouldBeEnabled forKey:@"scrollwheel"];
}

- (BOOL)scrollWheelZoomEnabled
{
    return [m_options valueForKey:@"scrollwheel"];
}

- (void)setOptions:(CPDictionary)opts
{
    [m_options _setOptionsFromDictionary:opts];
}

- (void)addAnnotation:(MKAnnotation)annotation
{
	[self addAnnotations:[CPArray arrayWithObject:annotation]];
}

- (void)addAnnotations:(CPArray)anAnnotationArray
{
    if (m_map)
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
	var annotationsCount = [aAnnotationArray count];

	for (var i = 0; i < annotationsCount; i++)
	{
		var annotation = aAnnotationArray[i];

		var marker = null;

		if ([markerDictionary valueForKey:[annotation UID]])
		{
			marker = [markerDictionary valueForKey:[annotation UID]];
			marker.setMap(m_map);
		}
		else
		{
			var marker = new google.maps.Marker({
    			position: LatLngFromCLLocationCoordinate2D([annotation coordinate]),
    			map: m_map
	  		});

  			[markerDictionary setValue:marker forKey:[annotation UID]];
		}

		[annotations addObject:annotation];
	};
}

- (void)removeAnnotation:(MKAnnotation)annotation
{
	[self removeAnnotations:[CPArray arrayWithObject:annotation]];
}

- (void)removeAnnotations:(CPArray)aAnnotationArray
{
	var annotationsCount = [aAnnotationArray count];

	for (var i =0; i < annotationsCount; i++)
	{
		var annotation = aAnnotationArray[i]

		if(annotation)
		{
			var marker = [markerDictionary valueForKey:[annotation UID]];

			if(marker)
	  		{
				marker.setMap(null);
				[markerDictionary setValue:null forKey:[annotation UID]];
	  		}

			[annotations removeObject:annotation];
		}
	};
}

- (void)layoutSubviews
{
    if (m_map)
	   google.maps.event.trigger(m_map, 'resize');
}

@end

var MKMapViewCenterCoordinateKey    = @"MKMapViewCenterCoordinateKey",
    MKMapViewZoomLevelKey           = @"MKMapViewZoomLevelKey",
    MKMapViewMapTypeKey             = @"MKMapViewMapTypeKey";

@implementation MKMapView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self setCenterCoordinate:CLLocationCoordinate2DFromString([aCoder decodeObjectForKey:MKMapViewCenterCoordinateKey])];
        [self setZoomLevel:[aCoder decodeObjectForKey:MKMapViewZoomLevelKey]];
        [self setMapType:[aCoder decodeObjectForKey:MKMapViewMapTypeKey]];
        [self setScrollWheelZoomEnabled:YES];

        [self _init];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{    
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:CPStringFromCLLocationCoordinate2D([self centerCoordinate]) forKey:MKMapViewCenterCoordinateKey];
    [aCoder encodeObject:[self zoomLevel] forKey:MKMapViewZoomLevelKey];
    [aCoder encodeObject:[self mapType] forKey:MKMapViewMapTypeKey];
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
