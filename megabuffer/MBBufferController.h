//
//  MBBufferController.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 20/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDocument;

@interface MBBufferController : NSObject
@property (strong, atomic) NSTimer *timer;
@property (strong, atomic) NSNumber * fps;
@property bool recording;

- (id) initWithDocument: (BDocument *)bufferDocument;

@end
