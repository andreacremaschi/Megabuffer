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

@property (strong) id syphonOut;
@property (unsafe_unretained) MBBufferObject * buffer;

@property (strong, nonatomic) NSString * serverName;

@property (strong, nonatomic) NSNumber *rate;
@property (strong, nonatomic) NSNumber *delay;
@property (strong, nonatomic) NSNumber *scrubMode;


// Persistence
- (BOOL) setupWithDictionary: (NSDictionary *)dict;

- (CIImage *)currentFrame;
- (void) stop;
- (bool)initOpenGLContextWithSharedContext: (NSOpenGLContext*)sharedContext error: (NSError **)error;

- (void) gotoPreviousMarker;
- (void) gotoNextMarker;

@end
