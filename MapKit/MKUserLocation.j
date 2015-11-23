@implementation MKUserLocation : CPObject <MKAnnotation>
{
    CLLocationCoordinate2D  _location @accessors(getter=location, setter=_setLocation:);
    CPInteger               _heading  @accessors(getter=heading, setter=_setHeading:);
    CPInteger               _accuracy @accessors;
    BOOL                    _updating @accessors(getter=isUpdating, setter=_setUpdating:);
    CPString                _title    @accessors(property=title);
    CPString                _subtitle @accessors(property=subtitle);
}

- (id)init
{
    self = [super init];

    _location = nil;
    _heading = 0;
    _accuracy = CPNotFound;
    _updating = NO;

    _title = nil;
    _subtitle = nil;

    return self;
}

- (CLLocationCoordinate2D)coordinate
{
    return _location;
}

@end