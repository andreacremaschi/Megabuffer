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
@property (strong) NSString *syInServerName;
@property (strong) NSString *syInApplicationName;

// bufferSize e maxDelay sono interdipendenti:
// maxDelay = bufferSize / fps
@property NSNumber * bufferSize;
@property NSTimeInterval maxDelay;

@property bool _recording;

@property (strong, nonatomic) NSMutableStack * frameStack;
@property (strong, nonatomic) NSMutableArray * markersArray;

-(id)initWithOpenGLContext: (NSOpenGLContext *)context;

-(void)setServerDescription:(NSDictionary *)serverDescription;

- (CIImage *)ciImageAtTime: (NSTimeInterval) time;
- (NSDictionary *)imageDictForDelay: (NSTimeInterval)delay;

- (NSTimeInterval) firstFrameInBufferTimeStamp;
- (NSTimeInterval) lastFrameInBufferTimeStamp;

// markers
-(void) addMarkerToNextFrame;
- (NSTimeInterval) markerPrecedingPosition: (NSTimeInterval) indexTimeStamp;
- (NSTimeInterval) markerFollowingPosition: (NSTimeInterval) indexTimeStamp;

- (void) setRecording: (NSNumber *)recording;

@end
