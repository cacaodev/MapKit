@implementation MKDirectionsResponse : CPObject
{
    MKMapItem _source      @accessors(property=source);
    MKMapItem _destination @accessors(property=destination);
    CPArray   _routes      @accessors(property=routes);
}

- (CPString)description
{
    return "<" + [self className] + " source:" + _source + " destination:" + _destination + " routes:" + [_routes description] + ">";
}

@end