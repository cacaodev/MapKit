@import "MKDirectionsRequest.j"
@import "MKDirectionsResponse.j"
@import "MKRoute.j"

@global google
var _DirectionsService = NULL;

@implementation MKDirections : CPObject
{
    BOOL _calculating @accessors(readonly, getter=isCalculating);
    MKDirectionsRequest _request;
}

+ (id)directionsService
{
    if (_DirectionsService == NULL) {
        _DirectionsService = new google.maps.DirectionsService();
    }

    return _DirectionsService;
}

- (id)initWithRequest:(MKDirectionsRequest)aRequest
{
    self = [super init];

    _request = aRequest;
    _calculating = NO;

    return self;
}

- (void)cancel
{
}

- (void)calculateDirectionsWithCompletionHandler:(Function/*MKDirectionsResponse response, CPError error*/)completionHandler
{
    if (_calculating)
    {
        completionHandler(nil, @"MKDirection is already calculating the route.");
        return;
    }

    var service = [[self class] directionsService],
        g_request = [_request toJSON];

    service.route(g_request, function(results, status)
    {
        if (status == google.maps.DirectionsStatus.OK)
        {
            var response = [[MKDirectionsResponse alloc] init];
            [response setSource:[_request source]];
            [response setDestination:[_request destination]]; // ???

            var routes = [results.routes arrayByApplyingBlock:function(g_route, idx)
            {
                return [[MKRoute alloc] initWithJSON:g_route];
            }];

            [response setRoutes:routes];

            completionHandler(response, nil);
        }
        else
        {
            completionHandler(nil, status);
        }

        _calculating = NO;
    });

    _calculating = YES;
}

@end
