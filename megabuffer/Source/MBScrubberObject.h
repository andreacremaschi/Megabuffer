//
//  MBScrubberObject.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBCanvas.h"

typedef enum {
    MBScrubMode_off,
    MBScrubMode_rate,
    MBScrubMode_speed
} scrubModes;

@class MBBufferObject;

@interface MBScrubberObject : MBCanvas
@property double rate;
@property double delay;
@property scrubModes scrubMode;

@property (strong) id syphonOut;
@property (unsafe_unretained) MBBufferObject * buffer;

@property (strong, nonatomic) NSString * serverName;

- (CIImage *)currentFrame;
- (void) stop;
- (bool)initOpenGLContextWithSharedContext: (NSOpenGLContext*)sharedContext error: (NSError **)error;

@end
