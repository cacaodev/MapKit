
@import <Foundation/CPObject.j>

@implementation MKPlacemark : CPObject
{
   CPDictionary adressDictionary        @accessors(readonly);
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

- (id)initWithJSON:(JSObject)aJson
{
	var addDic  = [[CPMutableDictionary alloc] init];
       	
  	for (var i = 0; i < aJson.address_components.length; i++) {
		  var component =  aJson.address_components[i];
       		  
  		 for (var j=0; j < component.types.length; j++) {
     			var type = component.types[j];
      			if(j == 0)
       			{
        			[addDic setValue:component.long_name forKey:type];
       			}
      			
       			if(j == 1)
       			{
        			[addDic setValue:component.short_name forKey:type];
       			}
       		};
      };	
      
    var aCoordinate = nil;

    if(aJson && aJson && aJson.geometry)
    {
	    var resultLatLng = aJson.geometry.location;
	    aCoordinate = CLLocationCoordinate2DFromLatLng(resultLatLng);
    }        	
    
    if(self = [self initWithCoordinate:aCoordinate addressDictionary:addDic])
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
        self.adressDictionary = aAddressDictionary;
                
        //Street and Streetnumber        
        if([adressDictionary containsKey:@"route"])
        {
	       [self setValue:[adressDictionary valueForKey:@"route"] forKey:@"thoroughfare"];
        }
        
        if([adressDictionary containsKey:@"street_number"])
        {
	       [self setValue:[adressDictionary valueForKey:@"street_number"] forKey:@"subThoroughfare"];
        }

        if([adressDictionary containsKey:@"locality"])
        {
	       [self setValue:[adressDictionary valueForKey:@"locality"] forKey:@"locality"];
        }

		if([adressDictionary containsKey:@"sublocality"])
        {
	       [self setValue:[adressDictionary valueForKey:@"sublocality"] forKey:@"subLocality"];
        }

        if([adressDictionary containsKey:@"administrative_area_level_1"])
        {
	       [self setValue:[adressDictionary valueForKey:@"administrative_area_level_1"] forKey:@"administrativeArea"];
        }


        if([adressDictionary containsKey:@"administrative_area_level_2"])
        {
	       [self setValue:[adressDictionary valueForKey:@"administrative_area_level_2"] forKey:@"subAdministrativeArea"];
        }

		if([adressDictionary containsKey:@"country"])
        {
	       [self setValue:[adressDictionary valueForKey:@"country"] forKey:@"country"];
        }


        if([adressDictionary containsKey:@"political"])
        {
	       [self setValue:[adressDictionary valueForKey:@"political"] forKey:@"countryCode"];
        }


        if([adressDictionary containsKey:@"postal_code"])
        {
	       [self setValue:[adressDictionary valueForKey:@"postal_code"] forKey:@"postalCode"];
        }
    }
    return self;
}

- (CPString)description
{
    return "< " + [self className] + " " + formattedAddress +  " " + CPStringFromCLLocationCoordinate2D(coordinate) + " >";
}
@end
