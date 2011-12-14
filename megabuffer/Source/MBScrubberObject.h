//
//  MBScrubberObject.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MBScrubMode_off,
    MBScrubMode_rate,
    MBScrubMode_speed
} scrubModes;

@class MBBufferObject;

@interface MBScrubberObject : NSObject
@property double rate;
@property double delay;
@property scrubModes scrubMode;

@property (strong) id syphonOut;
@property (unsafe_unretained) MBBufferObject * buffer;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSOpenGLContext *_openGLContext;
@property (strong, nonatomic) NSOpenGLPixelFormat *_pixelFormat;

- (CIImage *)currentFrame;
- (void) stop;
- (bool)initOpenGLContextWithSharedContext: (NSOpenGLContext*)sharedContext error: (NSError **)error;

@end