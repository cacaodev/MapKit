@import <Foundation/CPArray.j>

@implementation CPArray (Additions)

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
