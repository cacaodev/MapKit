/* Abstract class */

@implementation MKShape : CPObject
{
    CPString _title    @accessors(property=title)
    CPString _subtitle @accessors(property=subtitle)
}

- (id)coordinate
{
}

- (id)setCoordinate:(id)aCoordinate
{
}

@end