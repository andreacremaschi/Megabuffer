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



#define IN_MARKER_THRESHOLD 0.1

@interface MBScrubberObject () {
    CGSize _currentSize;
    NSTimeInterval scrubStart;
    NSTimeInterval lastUpdateTimeStamp;
}
@property double _rate;
//@property double _delay;
@property double _delay;

@property double _autoScrubDuration;

@property double _isInAutoScrub;
@property double _autoScrubStartTime;
@property double _autoScrubEndTime;
@property double _autoScrubTargetDelay;
@property double _scrubStep;

@property scrubModes _scrubMode;

@property NSTimeInterval _selectedMarker;


//@property (strong, nonatomic) NSOperation *_autoScrubOperation;

@end

@implementation MBScrubberObject
@synthesize _rate;
@synthesize _delay;
@synthesize _scrubMode;
@synthesize syphonOut;
@synthesize buffer;
//@synthesize _autoScrubOperation;
@synthesize _autoScrubDuration;

@synthesize _autoScrubStartTime;
@synthesize _autoScrubEndTime;
@synthesize _autoScrubTargetDelay;
@synthesize _scrubStep;
@synthesize _isInAutoScrub;

@synthesize _selectedMarker;

@synthesize serverName;

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self)
    {
        self.name = @"scrubber";

        // Kick off a new Thread
        [NSThread detachNewThreadSelector:@selector(createTimer) toTarget:self withObject:nil];

        _scrubMode = MBScrubMode_off;
        _selectedMarker=0;
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

#pragma mark - KVO
+(NSSet *)keyPathsForValuesAffectingReverseDelay
{
    return [NSSet setWithObject:@"delay"];
}

#pragma mark - Attributes
- (NSSet *)attributes
{
    return [[super attributes] setByAddingObjectsFromSet:[NSSet setWithObjects: @"delay", @"scrubMode", @"rate", @"gotoNextMarker", @"gotoPrevMarker", @"gotoMarkerWithLabel", @"autoScrubToDelay", @"autoScrubDuration", @"gotoDelay", nil]];
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

- (NSNumber *) reverseDelay
{   return [NSNumber numberWithDouble: buffer.maxDelay - _delay]; }

- (void) setReverseDelay: (NSNumber *)revDelay
{   self.delay = [NSNumber numberWithDouble: buffer.maxDelay - revDelay.doubleValue]; }

- (void) setRate: (NSNumber *)newVal
{   _rate = [newVal doubleValue]; }

- (NSNumber *) rate
{   return [NSNumber numberWithDouble:_rate]; }

- (NSNumber *) autoScrubTargetDelay
{   return [NSNumber numberWithDouble:_autoScrubTargetDelay]; }

-(void)setAutoScrubTargetDelay:(NSNumber *)newVal
{
    _autoScrubTargetDelay = newVal.doubleValue;
}

- (void) setGotoNextMarker: (id)options
{   [self gotoNextMarker]; }

- (void) setGotoPrevMarker: (id)options
{   [self gotoPreviousMarker]; }

- (void) setGotoMarkerWithLabel: (NSString *)label
{  //TODO: implementare
}

- (void) setGotoDelay: (NSNumber *)value
{
    [self gotoDelay:value];

}

- (void) setScrubMode: (id)options
{  //TODO: implementare
}

- (id) scrubMode
{  //TODO: implementare
    return [NSNumber numberWithInt:0];
}

- (void) setAutoScrubDuration: (NSNumber *)newVal
{   _autoScrubDuration= [newVal doubleValue]; }

- (NSNumber *) autoScrubDuration
{   return [NSNumber numberWithDouble:_autoScrubDuration]; }



- (void) autoScrubToDelay: (NSNumber *)delay
{
//    if (_autoScrubOperation) return;
  
    if (_isInAutoScrub) return;
    
     NSNumber * initDelay = [self.delay copy];
     NSNumber *outDelay = [delay copy];
     NSTimeInterval startTime = lastUpdateTimeStamp;
     NSTimeInterval scrubTime = _autoScrubDuration;
     NSTimeInterval endTime = startTime + scrubTime;
   //  double scrubStep = scrubTime / (outDelay.doubleValue - initDelay.doubleValue);

   /* __block NSBlockOperation* autoScrubOperation = [NSBlockOperation blockOperationWithBlock:^{

        
        NSLog(@"qui");
        if (lastUpdateTimeStamp > endTime)
        {
        NSLog(@"quo");
            [autoScrubOperation cancel];
        }
        else
        {
                    NSLog(@"qua");
            double newDelayValue = _delay + scrubStep;
            self.delay = [NSNumber numberWithDouble: newDelayValue];
        }
    }];
    _autoScrubOperation = autoScrubOperation;*/
    //_scrubStep = scrubStep;
    _autoScrubStartTime = lastUpdateTimeStamp;
    _autoScrubEndTime = endTime;
    
    [self willChangeValueForKey:@"autoScrubTargetDelay"];
    _autoScrubTargetDelay = delay.doubleValue;
    [self didChangeValueForKey:@"autoScrubTargetDelay"];
    _isInAutoScrub= YES;
    
}

- (void) setAutoScrubToDelay: (NSNumber *)delay
{
    [self autoScrubToDelay:delay];
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

    
    // auto scrub
/*    if (_autoScrubOperation ) 
    {   [_autoScrubOperation start];
        [_autoScrubOperation waitUntilFinished];
//        [[NSOperationQueue currentQueue] addOperation: _autoScrubOperation];   
    }

    if ([_autoScrubOperation isCancelled])
        _autoScrubOperation = nil;*/
    
    
    NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate] - scrubStart;
    NSTimeInterval deltaTime = lastUpdateTimeStamp - curTime;
    lastUpdateTimeStamp = curTime;

    double framesStep;
    if (_isInAutoScrub)
    {
        if (_autoScrubEndTime < curTime)
            _isInAutoScrub = NO;
        else
        {
            NSTimeInterval scrubTime = _autoScrubEndTime - curTime;
            double scrubStep = (_autoScrubTargetDelay - _delay) / scrubTime;

            framesStep= scrubStep * 1/ self.fps.doubleValue;

        }
        
    }
    
    
    if (!_isInAutoScrub)
        framesStep = deltaTime * (buffer._recording? _rate - 1 : _rate);
//    delay += framesStep * rate;
    
    
    NSTimeInterval newDelay = _delay + framesStep;

    newDelay = newDelay < 0 ? 0 : newDelay;
    newDelay = newDelay > [buffer.bufferSize intValue] / [buffer.fps doubleValue] ? [buffer.bufferSize intValue] / [buffer.fps doubleValue] : newDelay;
    [self set_delay: newDelay ];

    // controlla se siamo usciti dall'area del marker
    if (!_isInAutoScrub)
    {
        if ((_selectedMarker> 0) && (fabs(_delay + _selectedMarker - self.buffer.firstFrameInBufferTimeStamp)> IN_MARKER_THRESHOLD)) 
        {
            //NSLog (@"%.2f, %.2f, %.2f", _delay, _selectedMarker, self.buffer.firstFrameInBufferTimeStamp);
            _selectedMarker = 0;
        }
    }
    
    //NSLog(@"Posizione scrubber: %.4f", _delay);
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
                           imageRegion: frame
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
- (void)gotoDelay:(NSNumber *)value
{
    if (_autoScrubDuration>0) 
        [self autoScrubToDelay:value];
    else 
        [self setDelay:value];
}

- (void) gotoPreviousMarker
{
    NSTimeInterval curPosition = _selectedMarker ? _selectedMarker : self.buffer.firstFrameInBufferTimeStamp - self._delay;
    NSTimeInterval prevMarker = [self.buffer markerPrecedingPosition: curPosition];
    if (prevMarker)
    {
        _selectedMarker= prevMarker;
        NSTimeInterval newDelayValue = self.buffer.firstFrameInBufferTimeStamp - prevMarker;
        [self gotoDelay: [NSNumber numberWithDouble:newDelayValue]];
        
    }
}

- (void) gotoNextMarker
{

    NSTimeInterval curPosition = _selectedMarker ? _selectedMarker : self.buffer.firstFrameInBufferTimeStamp - self._delay;
    NSTimeInterval nextMarker = [buffer markerFollowingPosition: curPosition];    
    if (nextMarker)
    {
        _selectedMarker= nextMarker;
        NSTimeInterval newDelayValue = self.buffer.firstFrameInBufferTimeStamp - nextMarker;
        [self gotoDelay: [NSNumber numberWithDouble:newDelayValue]];
    }
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
