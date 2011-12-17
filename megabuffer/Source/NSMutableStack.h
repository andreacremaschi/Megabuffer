//
//  NSMutableStack.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableStack : NSObject

@property NSUInteger maxObjects;

- (NSUInteger) count;
- (id)objectAtIndex:(NSUInteger)index;

- (id)push:(id)object;
- (id) lastObject;

@end
