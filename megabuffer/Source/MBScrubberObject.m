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
@property double _rate;
@property double _delay;
@property scrubModes _scrubMode;


@end

@implementation MBScrubberObject
@synthesize _rate;
@synthesize _delay;
@synthesize _scrubMode;
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

        _scrubMode = [NSNumber numberWithInt:0];
    }
    return self;
}


-(void)dealloc 
{

    buffer=nil;
}

#pragma mark - Accessors
/*- (void) _setDelay: (double) newVal
{
    _delay = newVal;
}
*/


#pragma mark - Attributes
- (NSSet *)attributes
{
    return [[super attributes] setByAddingObjectsFromSet:[NSSet setWithObjects: @"delay", @"scrubMode", @"rate", @"gotoNextMarker", @"gotoPrevMarker",@"gotoMarkerWithLabel", nil]];
}

- (void) setDelay: (NSNumber *)newVal
{   [self set_delay: [newVal doubleValue]]; }

+ (NSSet *)keyPathsForValuesAffectingRate
{
    return [NSSet setWithObject:@"_rate"];
}
+ (NSSet *)keyPathsForValuesAffectingDelay
{
    return [NSSet setWithObject:@"_delay"];
}
- (NSNumber *) delay
{   return [NSNumber numberWithDouble:_delay]; }

- (void) setRate: (NSNumber *)newVal
{   _rate = [newVal doubleValue]; }

- (NSNumber *) rate
{   return [NSNumber numberWithDouble:_rate]; }

- (void) setGotoNextMaker: (id)options
{   [self gotoNextMarker]; }

- (void) setGotoPrevMaker: (id)options
{   [self gotoPreviousMarker]; }

- (void) setGotoMarkerWithLabel: (NSString *)label
{  //TODO: implementare
}

- (void) setScrubMode: (id)options
{  //TODO: implementare
}

- (id) scrubMode
{  //TODO: implementare
    return [NSNumber numberWithInt:0];
}

#pragma mark - Server creation

- (void)setServerName:(NSString *)object
{
    @synchronized(syphonOut)
    {
        syphonOut = nil;
    }
    syphonOut = [[SyphonServer alloc] initWithName:	 object
                                           context:		self.openGLContext.CGLContextObj
                                           options:		nil]; 
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
    
    double framesStep = deltaTime * 1/ [self.fps doubleValue];
//    delay += framesStep * rate;
    NSTimeInterval newDelay = _delay + (buffer._recording? _rate -1 : _rate) * deltaTime;
    newDelay = newDelay < 0 ? 0 : newDelay;
    newDelay = newDelay > [buffer.bufferSize intValue] / [buffer.fps doubleValue] ? [buffer.bufferSize intValue] / [buffer.fps doubleValue] : newDelay;
    [self set_delay: newDelay ];
    
    NSDictionary *imageDict =[self.buffer imageDictForDelay: _delay];
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
    @synchronized(syphonOut)
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
    NSTimeInterval prevMarker = [self.buffer markerPrecedingPosition: self.buffer.firstFrameInBufferTimeStamp- self._delay];
    if (prevMarker)
        [self set_delay: self.buffer.firstFrameInBufferTimeStamp - prevMarker];    
}

- (void) gotoNextMarker
{
    NSTimeInterval nextMarker = [buffer markerFollowingPosition: self.buffer.firstFrameInBufferTimeStamp  - self._delay];
    if (nextMarker)
        [self set_delay: self.buffer.firstFrameInBufferTimeStamp - nextMarker];
}

#pragma mark -Serialization
- (NSDictionary *)dictionaryRepresentation
{
    NSDictionary*dict= [NSDictionary dictionaryWithObjectsAndKeys:
            self.name ? self.name : @"", @"name",
            self.rate, @"rate",
            self.delay, @"delay",
            self.serverName, @"serverName",
            self.scrubMode, @"scrubMode",
            self.fps, @"fps",
            nil];
    return dict;
}

- (BOOL) setupWithDictionary: (NSDictionary *)dict
{
    self.name = [dict objectForKey:@"name"];
    self.rate = [dict objectForKey:@"rate"] ;
    self.delay = [dict objectForKey:@"delay"] ;
    self.serverName = [dict objectForKey:@"serverName"] ;
    self.scrubMode = [dict objectForKey:@"scrubMode"] ;
    self.fps = [dict objectForKey:@"fps"] ;
    return YES;
}

@end
