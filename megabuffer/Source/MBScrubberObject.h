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
@property (unsafe_unretained, readonly, nonatomic) NSNumber *reverseDelay;
@property (strong, nonatomic) NSNumber *scrubMode;
@property (strong, nonatomic) NSNumber *autoScrubDuration;
@property (strong, nonatomic) NSNumber *autoScrubTargetDelay;
@property (readonly) NSTimeInterval scrubberPosition;
@property (readwrite, nonatomic) double percentualDelay;
@property (readwrite, nonatomic) double percentualAutoScrubTargetDelay;

// Persistence
- (BOOL) setupWithDictionary: (NSDictionary *)dict;

- (CIImage *)currentFrame;
- (void) stop;
- (bool)initOpenGLContextWithSharedContext: (NSOpenGLContext*)sharedContext error: (NSError **)error;

- (void) gotoPreviousMarker;
- (void) gotoNextMarker;

- (void) autoScrubToDelay: (NSNumber *)delay;
- (void) gotoDelay: (NSNumber *) value;

@end
