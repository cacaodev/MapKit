@class CPArray;

@implementation CPArray (Additions)

- (CPArray)arrayByApplyingBlock:(Function)aFunction
{
    return self.map(aFunction);
}

- (CPArray)objectsPassingTest:(Function)aFunction
{
    var result = [CPArray array];

    [self enumerateObjectsUsingBlock:function(obj, idx, stop)
    {
        if (aFunction(obj, idx))
            [result addObject:obj];
    }];

    return result;
}

@end