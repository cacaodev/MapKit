
var CALLBACK_PARAMETERS = [],
    _CachedScriptLoader = {};

@implementation ScriptLoader : CPObject
{
    ScriptOperation  _operation @accessors(property=operation);
    CPOperationQueue _queue;
    CPArray          _pendingInvocations;
    BOOL             _loading;
}

+ (void)loadScriptURL:(CPString)aStringURL callbackParameter:(CPString)callback completionFunction:(Function)aFunction
{
    var loader = [ScriptLoader scriptWithURL:aStringURL callbackParameter:callback],
        loaderOperation = [loader operation];

    [loader addCompletionFunction:aFunction];

    if (![loaderOperation isFinished] && ![loaderOperation isExecuting])
        [loader load];

    return loader;
}

- (void)addCompletionFunction:(Function)aFunction
{
    if (!aFunction)
        return;

    if ([_operation isFinished])
        aFunction();
    else
        [[_operation completionFunctions] addObject:aFunction];
}

+ (ScriptLoader)scriptWithURL:(CPString)aURL callbackParameter:(CPString)callback
{
    var script = _CachedScriptLoader[aURL];
    if (!script)
    {
        script = [[ScriptLoader alloc] initWithURL:aURL callbackParameter:callback];
        _CachedScriptLoader[aURL] = script;
    }

    return script;
}

- (id)initWithURL:(CPString)aStringURL callbackParameter:(CPString)callback
{
    self = [super init];

    _operation = [[ScriptOperation alloc] initWithScriptURL:aStringURL];
    [_operation setCallbackParameter:callback];
    _queue = [[CPOperationQueue alloc] init];
    _pendingInvocations = [CPArray array];
    _loading = NO;

    return self;
}

- (void)setcallbackParameter:(CPString)callback
{
    if (!callback)
        return;

    if (CALLBACK_PARAMETERS.indexOf(callback) !== -1)
    {
        CPLog.error("This callback has already been used.");
        return;
    }

    CALLBACK_PARAMETERS.push(callback);
    [_operation setcallbackParameter:callback];
}

- (void)load
{
    if (_loading)
    {
        CPLog.warn("The script is already loading or loaded. Aborting loading.");
        return;
    }

    [_queue addOperation:_operation];

    _loading = YES;
}

- (void)invoqueWhenLoaded:(CPInvocation)anInvocation
{
    [self invoqueWhenLoaded:anInvocation ignoreMultiple:NO];
}

- (void)invoqueWhenLoaded:(CPInvocation)anInvocation ignoreMultiple:(BOOL)ignore
{
    if (!_operation)
        return;

    if ([_operation isFinished])
        [anInvocation invoke];
    else if (!ignore || ![_pendingInvocations containsObject:anInvocation])
    {
        var op = [[CPInvocationOperation alloc] initWithInvocation:anInvocation];
        [self addOperation:op];
        [_pendingInvocations addObject:anInvocation];
    }
}

- (void)addOperation:(CPOperation)op withName:(CPString)aName dependentOn:(CPString)dep oneShot:(BOOL)oneShot
{
    if (dep)
    {
        [_addedOperations enumerateObjectsUsingBlock:function(anOp, idx, stop)
        {
            if ([anOp objectForKey:@"name"] == dep)
            {
                [op addDependency:anOp];
                stop(YES);
            }
        }];
     }

    if (![_operation isFinished])
    {
        var opobject = [CPDictionary dictionaryWithObjectsAndKeys:op, @"operation", aName, @"name"];

        if (!oneShot || ![_addedOperations containsObject:opobject])
        {
            [self addOperation:op];
            [_addedOperations addObject:opobject];
        }
    }
    else
        [self addOperation:op];
}

- (void)addOperation:(CPOperation)anOperation
{
    [anOperation addDependency:_operation];
    [_queue addOperation:anOperation];
}

@end

@implementation ScriptOperation : CPOperation
{
    CPString _source;
    CPString _callbackParameter    @accessors(property=callbackParameter);
    CPArray  m_completionFunctions @accessors(readonly, getter=completionFunctions);
    BOOL     m_executing;
    BOOL     m_finished;
    BOOL     m_started;
}

- (id)initWithScriptURL:(CPString)aScriptURL
{
    self = [super init];

    _source = aScriptURL;
    _callbackParameter =nil;
    m_executing = NO;
    m_finished = NO;
    m_completionFunctions = [CPArray array];
    m_started = NO;

    return self;
}

- (void)start
{
    // Ensure this operation is not being restarted and that it has not been cancelled
    if ( m_started || m_finished || [self isCancelled] )
    {
        [self done];
        return;
    }

    // From this point on, the operation is officially executing--remember, isExecuting
    // needs to be KVO compliant!
    [self willChangeValueForKey:@"isExecuting"];
    m_executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

    // load the script
    [self loadScript];

    m_started = YES;
}

- (void)loadScript
{
    var DOMScriptElement = document.createElement("script");
    DOMScriptElement.src = _source;
    DOMScriptElement.type = "text/javascript";

    var ScriptLoaded = function ()
    {
        [self willChangeValueForKey:@"isExecuting"];
        m_executing = NO;
        [self didChangeValueForKey:@"isExecuting"];

        [self willChangeValueForKey:@"isFinished"];
        if (!_callbackParameter)
            DOMScriptElement.removeEventListener("load", ScriptLoaded, false);
        else
            eval(_callbackParameter + " = nil");

        m_finished = YES;
        [self didChangeValueForKey:@"isFinished"];

        [m_completionFunctions enumerateObjectsUsingBlock:function(aFunction, idx)
        {
            aFunction();
        }];

        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    }

    if (!_callbackParameter)
         DOMScriptElement.addEventListener("load", ScriptLoaded, false);
    else
        eval(_callbackParameter + " = ScriptLoaded");

     var head = document.getElementsByTagName("head")[0];
     head.appendChild(DOMScriptElement);
     CPLog.debug("Added script element");
}

- (BOOL)isExecuting
{
    return m_executing;
}

- (BOOL)isFinished
{
    return m_finished;
}

- (BOOL)isConcurent
{
    return NO;
}

@end
