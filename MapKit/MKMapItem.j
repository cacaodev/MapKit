
@class MKPlacemark

var mapItemForCurrentLocation = nil;

@implementation MKMapItem : CPObject
{
    MKPlacemark   _placemark           @accessors(readonly, getter=placemark);
    BOOL          _isCurrentLocation   @accessors(readonly, getter=isCurrentLocation);
    CPString      _name                @accessors(property=name);
    CPString      _phoneNumber         @accessors(property=phoneNumber);
    CPURL         _url                 @accessors(property=url);
}

+ (MKMapItem)mapItemForCurrentLocation
{
    if (!mapItemForCurrentLocation)
        mapItemForCurrentLocation = [[MKMapItem alloc] initWithCurrentLocation];

    return mapItemForCurrentLocation;
}

- (id)initWithCurrentLocation
{
    self = [super init];

    _placemark = nil;
    _isCurrentLocation = YES;
    _name = @"Current Location";

    [self _init];

    return self;
}

- (id)initWithPlacemark:(MKPlacemark)aPlacemark
{
    self = [super init];

    _placemark = aPlacemark;
    _isCurrentLocation = NO;
    _name = nil;

    [self _init];

    return self;
}

- (void)_init
{
    _phoneNumber = nil;
    _url = nil;
}

- (CLLocationCoordinate2D)_coordinate
{
    if (_isCurrentLocation)
        return CLLocationCoordinate2DMake(-1, -1);

    return [_placemark coordinate];
}

- (CPString)description
{
    return "<" + [self className] + " coordinate:" + [self _coordinate] + ">";
}

@end
