//
//  MBScrubberObject.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBScrubberObject.h"


#import "MBBufferObject.h"
#import "NSMutableStack.h"

@interface MBScrubberObject () {
    CGSize _currentSize;
    NSTimeInterval scrubStart;
    NSTimeInterval lastUpdateTimeStamp;
}


@end

@implementation MBScrubberObject
@synthesize delay;
@synthesize scrubMode;
@synthesize rate;
@synthesize syphonOut;
@synthesize buffer;

@synthesize serverName;

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self)
    {

        // Kick off a new Thread
        [NSThread detachNewThreadSelector:@selector(createTimer) toTarget:self withObject:nil];

    }
    return self;
}


-(void)dealloc 
{

    buffer=nil;
    syphonOut = nil;
}


#pragma mark - Server creation

- (void)setServerName:(NSString *)object
{
    @synchronized(self)
    {
        syphonOut = [[SyphonServer alloc] initWithName:	 object
                                               context:		self.openGLContext.CGLContextObj
                                               options:		nil]; 
    }
    serverName=object;
    
}


-(void) _timerTick
{
    if (self.buffer.frameStack.count ==0) return;
    
    if (scrubStart == 0) 
        scrubStart = [NSDate timeIntervalSinceReferenceDate];

    NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate] - scrubStart;
    NSTimeInterval deltaTime = lastUpdateTimeStamp - curTime;
    lastUpdateTimeStamp = curTime;
    
    double framesStep = deltaTime * 1/self.fps;
//    delay += framesStep * rate;
    NSTimeInterval newDelay = delay + (buffer.recording? rate -1 : rate) * deltaTime;
    newDelay = newDelay < 0 ? 0 : newDelay;
    newDelay = newDelay > buffer.bufferSize / buffer.fps ? buffer.bufferSize / buffer.fps : newDelay;
    [self setDelay: newDelay ];
    
    NSDictionary *imageDict =[self.buffer imageDictForDelay: delay];
    if (!imageDict) return;
    
    
    CVPixelBufferRef pixelBuffer = [[imageDict valueForKey: @"image"] pointerValue];
    NSTimeInterval timeStamp = [[imageDict valueForKey: @"timeIndex"] doubleValue];
    NSDictionary *attributesDict =  (__bridge  NSDictionary *)CVOpenGLBufferGetAttributes(pixelBuffer);
    
    //CGRect frame = image.extent;
    CGRect frame = CGRectMake(0.0, 0.0, [[attributesDict valueForKey:@"Width"] doubleValue], [[attributesDict valueForKey:@"Height"] doubleValue]) ;
    if (CGRectEqualToRect(frame, CGRectZero)) return;
    
    CVPixelBufferRetain(pixelBuffer);
    
    CGLContextObj cgl_ctx = [self.openGLContext CGLContextObj];
    CGLLockContext(cgl_ctx);
    
    
    CVOpenGLTextureRef textureOut= [self createNewTextureFromBuffer: pixelBuffer];
    
    GLenum target = CVOpenGLTextureGetTarget(textureOut);
    GLint name = CVOpenGLTextureGetName(textureOut);     
    
    
    // publish our frame to our server. 
    @synchronized(self)
    {
        if (nil == syphonOut)
            [self setServerName: @"scrubber1"];
        [syphonOut publishFrameTexture: name
                         textureTarget: target
                           imageRegion: NSMakeRect(0, 0, frame.size.width, frame.size.height)
                     textureDimensions: frame.size
                               flipped: NO];
    }
    // let the renderer resume drawing
    //    [theRenderer unlockTexture];
    
    [self setCurrentTexture: textureOut];
    [self setCurrentFrameTimeStamp: timeStamp];
    CVOpenGLTextureRelease(textureOut);
    
    
    /*    // Restore OpenGL states
     glMatrixMode(GL_MODELVIEW);
     glPopMatrix();
     
     glMatrixMode(GL_PROJECTION);
     glPopMatrix();*/
    
    // back to main rendering.
    //glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    CGLUnlockContext(cgl_ctx);
    
    CVPixelBufferRelease(pixelBuffer);
}



- (CIImage *)currentFrame
{
    return buffer? [buffer ciImageAtTime: 0] : nil;
}

#pragma mark - Markers

- (void) gotoPreviousMarker
{
    NSTimeInterval prevMarker = [self.buffer markerPrecedingPosition: self.buffer.firstFrameInBufferTimeStamp- self.delay];
    if (prevMarker)
        [self setDelay: self.buffer.firstFrameInBufferTimeStamp - prevMarker];    
}

- (void) gotoNextMarker
{
    NSTimeInterval nextMarker = [buffer markerFollowingPosition: self.buffer.firstFrameInBufferTimeStamp  - self.delay];
    if (nextMarker)
        [self setDelay: self.buffer.firstFrameInBufferTimeStamp - nextMarker];
}

@end
