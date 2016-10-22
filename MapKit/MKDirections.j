@import "MKDirectionsRequest.j"
@import "MKDirectionsResponse.j"
@import "MKRoute.j"

@global google

@implementation MKDirections : CPObject
{
    BOOL _calculating @accessors(readonly, getter=isCalculating);
    MKDirectionsRequest _request;
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
        completionHandler(nil, nil);
        return;
    }

    var service = new google.maps.DirectionsService(),
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
