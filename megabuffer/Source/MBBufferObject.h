//
//  MBBufferObject.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBCanvas.h"
#import "SourceSyphon.h"



@class SourceSyphon,NSMutableStack;
@interface MBBufferObject : MBCanvas <TextureSourceDelegate>

@property (strong) SourceSyphon* syphonIn;
@property (copy, nonatomic) NSString *syInServerName;
@property (copy, nonatomic) NSString *syInApplicationName;

// bufferSize e maxDelay sono interdipendenti:
// maxDelay = bufferSize / fps
@property (copy) NSNumber * bufferSize;
@property NSTimeInterval maxDelay;
@property NSTimeInterval curTime;
@property NSTimeInterval curIndexTime;

@property bool _recording;

@property (strong, nonatomic) NSMutableStack * frameStack;
@property (strong, nonatomic) NSMutableArray * markersArray;

// Initialization
-(id)initWithOpenGLContext: (NSOpenGLContext *)context;

// Persistence
- (BOOL) setupWithDictionary: (NSDictionary *)dict;

// Other methods
-(void)setServerDescription:(NSDictionary *)serverDescription;

- (CIImage *)ciImageAtTime: (NSTimeInterval) time;
- (NSDictionary *)imageDictForDelay: (NSTimeInterval)delay;
- (NSDictionary *)imageDictForTimeIndex: (NSTimeInterval)scrubPosition;

- (NSTimeInterval) firstFrameInBufferTimeStamp;
- (NSTimeInterval) lastFrameInBufferTimeStamp;

// markers
-(void) addMarkerToNextFrame;
- (NSTimeInterval) markerPrecedingPosition: (NSTimeInterval) indexTimeStamp;
- (NSTimeInterval) markerFollowingPosition: (NSTimeInterval) indexTimeStamp;

- (void) setRecording: (NSNumber *)recording;

@end
