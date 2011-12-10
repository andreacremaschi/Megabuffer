//
//  NSMutableStack.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSMutableStack.h"

@implementation NSMutableStack
@synthesize maxObjects;

- (id)init
{
    self = [super init];
    if (self)
    {
        maxObjects = 250;
    }
    return self;
}

- (id)push:(id)object {
    id returnObject;
    @synchronized(self)
    {
        [self insertObject:object atIndex:0];
        if (self.count > maxObjects) 
        {
            returnObject = self.lastObject;
            [self removeLastObject];
        }
    }
    return returnObject;
}

- (void) addObject:(id)anObject 
{
    [self push: anObject];
}

- (id)pop {
    if (self.count > 0) {
        id returnObject = self.lastObject;
        [self removeLastObject];
        return returnObject;
    }
    else 
        return nil;
}

- (id)objectAtIndex:(NSUInteger)index 
{
    id object ;
    @synchronized(self)
    {
        object = [super objectAtIndex:index];
    }
    return object;
}

@end
