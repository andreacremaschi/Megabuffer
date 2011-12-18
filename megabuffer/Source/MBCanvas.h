//
//  MBCanvas.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 17/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "KeystoneTextureSourceProtocol.h"

#define MB_FPS 15.0 

@interface MBCanvas : NSObject  <KeystoneTextureSourceProtocol>
@property (strong, nonatomic) NSOpenGLContext *openGLContext;
@property (strong, nonatomic) NSOpenGLPixelFormat *pixelFormat;
@property (strong, nonatomic) NSTimer *timer;
@property CVOpenGLTextureRef currentTexture;
@property NSTimeInterval currentFrameTimeStamp;

@property int fps;

- (bool)initOpenGLContextWithSharedContext: (NSOpenGLContext*)sharedContext error: (NSError **)error;
- (CVOpenGLTextureRef)createNewTextureFromBuffer: (CVOpenGLBufferRef) pixelBuffer;

@end
