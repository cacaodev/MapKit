@implementation CPArray (Additions)

- (CPArray)arrayByApplyingBlock:(Function)aFunction
{
    return self.map(aFunction);
}

@end