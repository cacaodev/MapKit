@import "MKPlacemark.j"
@import "MKMapView.j"

@global google

@implementation MKGeocoder : CPObject
{
    Object          _geocoder;
    CPInvocation    _geocodeInvocation;
    BOOL            geocoding @accessors(readonly);
}

- (id)init
{
    self = [super init];

    _geocoder = nil;
    geocoding = NO;

    _geocodeInvocation = [[CPInvocation alloc] initWithMethodSignature:nil];
    [_geocodeInvocation setTarget:self];
    [_geocodeInvocation setSelector:@selector(_geocodeWithRequest:completionHandler:)];

    [self loadGoogleAPI];

    return self;
}

- (id)loadGoogleAPI
{
    var loader = [MKMapView GoogleAPIScriptLoader];

    [loader addCompletionFunction:function()
    {
        [self _buildGeocoder];
    }];

    [loader load];
}

- (void)_buildGeocoder
{
    _geocoder = new google.maps.Geocoder();
}

- (void)geocodeAddressString:(CPString)anAddress inRegion:(MKCoordinateRegion)region completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    var request = {address:anAddress};
    if (region)
    {
        var bounds = LatLngBoundsFromMKCoordinateRegion(region);
        request['bounds'] = bounds;
    }

    [self geocodeWithRequest:request completionHandler:completionHandler];
}

- (void)reverseGeocodeLocation:(CLLocationCoordinate2D)location completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    var latLng = LatLngFromCLLocationCoordinate2D(location);
    [self geocodeWithRequest:{latLng:latLng} completionHandler:completionHandler];
}

- (void)geocodeWithRequest:(Object)properties completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    if (_geocoder)
        [self _geocodeWithRequest:properties completionHandler:completionHandler];
    else
    {
        [_geocodeInvocation setArgument:properties atIndex:2];
        [_geocodeInvocation setArgument:completionHandler atIndex:3];

        [[MKMapView GoogleAPIScriptLoader] invoqueWhenLoaded:_geocodeInvocation ignoreMultiple:NO];
    }
}

- (void)_geocodeWithRequest:(Object)properties completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    geocoding = YES;

    _geocoder.geocode(properties, function(results, status)
    {
        var placemarks,
            error;

        if (status == google.maps.GeocoderStatus.OK)
        {
            error = nil;
            placemarks = [results arrayByApplyingBlock:function(result, idx)
            {
                return [[MKPlacemark alloc] initWithJSON:result];
            }];
        }
        else
        {
            error = [CPError errorWithDomain:CPCappuccinoErrorDomain code:-1 userInfo:ErrorUserInfoForStatus(status)];
            placemarks = nil;
        }

        completionHandler(placemarks, error);
        geocoding = NO;
    });
}

@end

var ErrorUserInfoForStatus = function(status)
{
    var geocoderSatus = google.maps.GeocoderStatus,
        localizedDescription = nil,
        failureReason = nil;

    switch (status)
    {
        case geocoderSatus.ZERO_RESULTS     : failureReason = "The geocode was successful but returned no results" ;
                                              localizedDescription = "No results";
        break;
        case geocoderSatus.OVER_QUERY_LIMIT : failureReason = "You are over your quota";
                                              localizedDescription = "Over Query Limit";
        break;
        case geocoderSatus.REQUEST_DENIED   : failureReason = "Your request was denied";
                                              localizedDescription = "Request Denied";
        break;
        case geocoderSatus.INVALID_REQUEST  : failureReason = "The query (address, components or latlng) is missing";
                                              localizedDescription = "Invalid Request";
        break;
        case geocoderSatus.UNKNOWN_ERROR    : failureReason = " The request could not be processed due to a server error";
                                              localizedDescription = "Unknown Error";
        break;
    }

    return @{CPLocalizedDescriptionKey:localizedDescription , CPLocalizedFailureReasonErrorKey:failureReason};
};
