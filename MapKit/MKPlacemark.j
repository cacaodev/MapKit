@import <Foundation/CPObject.j>
@import "MKGeometry.j"

var JSON_NAME_MAPPING =
{
    route:"thoroughfare",
    street_number:"subThoroughfare",
    locality:"locality",
    sublocality:"subLocality",
    administrative_area_level_1:"administrativeArea",
    administrative_area_level_2:"subAdministrativeArea",
    country:"country",
    political:"countryCode",
    postal_code:"postalCode"
};

@implementation MKPlacemark : CPObject
{
   CPDictionary             addressDictionary @accessors(readonly);
   CLLocationCoordinate2D   coordinate        @accessors();
   CPString                 title             @accessors();
   CPString                 subtitle          @accessors();
}

- (id)initWithJSON:(JSObject)aJson
{
	var addDic  = @{},
	    components = aJson.address_components;

  	for (var i = 0; i < components.length; i++)
  	{
        var component =  components[i];

  		for (var j = 0; j < component.types.length; j++)
  		{
            var type = component.types[j],
                key = JSON_NAME_MAPPING[type];

            if (j == 0)
                [addDic setValue:component.long_name forKey:key];

            if (j == 1)
                [addDic setValue:component.short_name forKey:key];
        }
    }

    [addDic setObject:aJson.formatted_address forKey:@"formattedAddress"];

    var aCoordinate = nil;

    if (aJson && aJson.geometry)
    {
	    var resultLatLng = aJson.geometry.location;
	    aCoordinate = CLLocationCoordinate2DFromLatLng(resultLatLng);
    }

    return [self initWithCoordinate:aCoordinate addressDictionary:addDic];
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate addressDictionary:(CPDictionary)aAddressDictionary
{
    self = [super init];

    coordinate = aCoordinate;
    addressDictionary = aAddressDictionary;
    title = nil;
    subtitle = nil;

    return self;
}

- (CPString)countryCode
{
    return [addressDictionary objectForKey:@"countryCode"];
}

- (CLLocationCoordinate2D)location
{
    return coordinate;
}

- (void)setLocation:(CLLocationCoordinate2D)aLocation
{
    coordinate = aLocation;
}

- (CPString)description
{
    return "< " + [self className] + " " + [addressDictionary objectForKey:@"formattedAddress"] +  ", " + CPStringFromCLLocationCoordinate2D(coordinate) + " >";
}

@end
