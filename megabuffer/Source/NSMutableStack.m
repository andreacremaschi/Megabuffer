//
//  NSMutableStack.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSMutableStack.h"

#pragma mark - Class Extension
@interface NSMutableStack () {
@private 
    NSMutableArray *_mutableArray;
}

@end 

#pragma mark - @implementation
@implementation NSMutableStack
@synthesize maxObjects;

- (id)init
{
    self = [super init];
    if (self)
    {
        _mutableArray = [NSMutableArray array];
        maxObjects = 250;
    }
    return self;
}

-(id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self)
    {
        maxObjects = numItems;
    }
    return self;
}

-(void)dealloc
{
    _mutableArray = nil;
}
#pragma mark - Methods

-(NSString *)description
{
    return _mutableArray.description;
}

- (NSUInteger)count
{
    return _mutableArray.count;
}

- (id)push:(id)object {
    id returnObject;
    @synchronized(self)
    {
        [_mutableArray insertObject:object atIndex:0];
        if (self.count > maxObjects) 
        {
            returnObject = _mutableArray.lastObject;
            [_mutableArray removeLastObject];
        }
    }
    return returnObject;
}

- (void) addObject:(id)anObject 
{
    [self push: anObject];
}

- (id)pop {
    id returnObject;
    @synchronized(self)
    {
        if (self.count > 0) {
            returnObject = _mutableArray.lastObject;
            [_mutableArray removeLastObject];
        }
        else 
            returnObject=nil;
    }
    return returnObject;

}

- (id)objectAtIndex:(NSUInteger)index 
{
    id object ;
    @synchronized(self)
    {
        object = [_mutableArray objectAtIndex:index];
    }
    return object;
}

- (id) lastObject
{
    return _mutableArray.lastObject;
}

@end
