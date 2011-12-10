//
//  NSMutableStack.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableStack : NSMutableArray

@property NSUInteger maxObjects;

- (id)push:(id)object;

@end
