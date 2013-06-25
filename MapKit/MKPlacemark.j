
@import <Foundation/CPObject.j>

@implementation MKPlacemark : CPObject
{
   CPDictionary addressDictionary       @accessors(readonly);
   CPString     thoroughfare            @accessors(readonly);
   CPString     subThoroughfare         @accessors(readonly);
   CPString     locality                @accessors(readonly);
   CPString     subLocality             @accessors(readonly);
   CPString     administrativeArea      @accessors(readonly);
   CPString     subAdministrativeArea   @accessors(readonly);
   CPString     postalCode              @accessors(readonly);
   CPString     country                 @accessors(readonly);
   CPString     countryCode             @accessors(readonly);
   CPString     formattedAddress        @accessors(readonly);

   CLLocationCoordinate2D coordinate    @accessors(readonly);
}

- (CPString)thoroughfare
{
    return [addressDictionary objectForKey:@"thoroughfare"];
}

- (CPString)subThoroughfare
{
    return [addressDictionary objectForKey:@"subThoroughfare"];
}

- (CPString)locality
{
    return [addressDictionary objectForKey:@"locality"];
}

- (CPString)subLocality
{
    return [addressDictionary objectForKey:@"subLocality"];
}

- (CPString)administrativeArea
{
    return [addressDictionary objectForKey:@"administrativeArea"];
}

- (CPString)subAdministrativeArea
{
    return [addressDictionary objectForKey:@"subAdministrativeArea"];
}

- (CPString)postalCode
{
    return [addressDictionary objectForKey:@"postalCode"];
}

- (CPString)country
{
    return [addressDictionary objectForKey:@"country"];
}

- (CPString)countryCode
{
    return [addressDictionary objectForKey:@"countryCode"];
}

- (CPString)formattedAddress
{
    return [addressDictionary objectForKey:@"formattedAddress"];
}


- (id)initWithJSON:(JSObject)aJson
{
	var addDic  = @{},
	    components = aJson.address_components;

  	for (var i = 0; i < components.length; i++)
  	{
        var component =  components[i];

  		for (var j=0; j < component.types.length; j++)
  		{
            var type = component.types[j];

            if (j == 0)
                [addDic setValue:component.long_name forKey:type];

            if (j == 1)
                [addDic setValue:component.short_name forKey:type];
        }
    }

    var aCoordinate = nil;

    if (aJson && aJson && aJson.geometry)
    {
	    var resultLatLng = aJson.geometry.location;
	    aCoordinate = CLLocationCoordinate2DFromLatLng(resultLatLng);
    }

    if (self = [self initWithCoordinate:aCoordinate addressDictionary:addDic])
    {
	    [self setValue:aJson.formatted_address forKey:@"formattedAddress"];
    }

    return self;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate addressDictionary:(CPDictionary)aAddressDictionary
{
    if (self = [super init])
    {
    	coordinate = aCoordinate;
        addressDictionary = aAddressDictionary;

        //Street and Streetnumber
        if ([addressDictionary containsKey:@"route"])
        {
	       [self setValue:[addressDictionary valueForKey:@"route"] forKey:@"thoroughfare"];
        }

        if ([addressDictionary containsKey:@"street_number"])
        {
	       [self setValue:[addressDictionary valueForKey:@"street_number"] forKey:@"subThoroughfare"];
        }

        if ([addressDictionary containsKey:@"locality"])
        {
	       [self setValue:[addressDictionary valueForKey:@"locality"] forKey:@"locality"];
        }

		if ([addressDictionary containsKey:@"sublocality"])
        {
	       [self setValue:[addressDictionary valueForKey:@"sublocality"] forKey:@"subLocality"];
        }

        if ([addressDictionary containsKey:@"administrative_area_level_1"])
        {
	       [self setValue:[addressDictionary valueForKey:@"administrative_area_level_1"] forKey:@"administrativeArea"];
        }

        if ([addressDictionary containsKey:@"administrative_area_level_2"])
        {
	       [self setValue:[addressDictionary valueForKey:@"administrative_area_level_2"] forKey:@"subAdministrativeArea"];
        }

		if ([addressDictionary containsKey:@"country"])
        {
	       [self setValue:[addressDictionary valueForKey:@"country"] forKey:@"country"];
        }

        if ([addressDictionary containsKey:@"political"])
        {
	       [self setValue:[addressDictionary valueForKey:@"political"] forKey:@"countryCode"];
        }

        if ([addressDictionary containsKey:@"postal_code"])
        {
	       [self setValue:[addressDictionary valueForKey:@"postal_code"] forKey:@"postalCode"];
        }
    }

    return self;
}

- (CPString)description
{
    return "< " + [self className] + " " + formattedAddress +  " " + CPStringFromCLLocationCoordinate2D(coordinate) + " >";
}

@end
