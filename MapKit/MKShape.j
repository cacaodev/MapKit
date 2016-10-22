/* Abstract class */
@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

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
