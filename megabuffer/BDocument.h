//
//  BDocument.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 17/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBBufferObject;
@class MBScrubberObject;

@interface BDocument : NSDocument
@property (strong, nonatomic) MBBufferObject *buffer;
@property (strong, nonatomic) MBScrubberObject *scrubber;
@end
