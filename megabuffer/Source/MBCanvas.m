//
//  MBCanvas.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 17/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBCanvas.h"
#import <OpenGL/CGLMacro.h>

@interface MBCanvas () {
    CVOpenGLTextureRef _texture;
    CVOpenGLTextureCacheRef _textureCache;
    bool dropNext;
}
- (void)timerFire:(NSTimer*)theTimer;
- (void) stop;
@property int  _fps;

@end

@implementation MBCanvas
@synthesize pixelFormat = _pixelFormat;
@synthesize openGLContext = _openGLContext;
@synthesize timer;
@synthesize currentFrameTimeStamp;
@synthesize fps;
@synthesize _fps;
@synthesize name;

- (id)init
{
    self = [super init];
    if (self)
    {
        NSError *error;
        
        // Kick off a new Thread
        [NSThread detachNewThreadSelector:@selector(createTimer) toTarget:self withObject:nil];
        
        _texture=0;
        _fps=MB_FPS;
        fps=[NSNumber numberWithInt: MB_FPS];

    }
    return self;
}

-(void)dealloc 
{
    [timer invalidate];
    CVOpenGLTextureRelease(_texture);
}

#pragma mark - Accessors
-(void)setFps:(NSNumber *)value
{
    [self willChangeValueForKey:@"fps"];
    [self stop];
    fps=[NSNumber numberWithDouble: fabs( value.doubleValue)];

    // Kick off a new Thread
    [NSThread detachNewThreadSelector:@selector(createTimer) toTarget:self withObject:nil];

    [self didChangeValueForKey:@"fps"];    
}

#pragma mark - Attributes
- (NSSet *)attributes
{
    return [NSSet setWithObjects:@"fps", nil];
}

#pragma mark - Graphical stuff init
- (bool)initOpenGLContextWithSharedContext: (NSOpenGLContext*)sharedContext error: (NSError **)error {
    
    NSOpenGLPixelFormatAttribute	attributes[] = {
		NSOpenGLPFAPixelBuffer,
		//NSOpenGLPFANoRecovery,
		//kCGLPFADoubleBuffer,
		//NSOpenGLPFAAccelerated,
		NSOpenGLPFADepthSize, 32,
		(NSOpenGLPixelFormatAttribute) 0
	};
    
	NSOpenGLPixelFormat*	newPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] ;
	
	NSOpenGLContext *newOpenGLContext = [[NSOpenGLContext alloc] initWithFormat:newPixelFormat 
                                                                   shareContext:sharedContext] ;
	if(newOpenGLContext == nil) {
		return false;
	}
	
	_openGLContext = newOpenGLContext ;	
	_pixelFormat = newPixelFormat;
	
    
	return true;
	
}


#pragma mark - Timer creation
- (void) createTimer{
    @autoreleasepool {
        
                dropNext=false;
        
        // Create a time for the thread
        timer = [NSTimer timerWithTimeInterval:1.0/ self.fps.doubleValue
                                        target:self 
                                      selector:@selector(timerFire:)
                                      userInfo:nil repeats:YES];
        // Add the timer to the run loop
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
        
    }        
}

#pragma mark - Timer

- (void) _timerTick
{ //non fare niente: per override
    return;
}
- (void)timerFire:(NSTimer*)theTimer
{

        
        if (dropNext) 
        {
            // NSLog(@"%@ drop a frame.", self);
            return;   
        }
        @synchronized(timer)
        {

            if ((!timer.isValid) )
                return;

            @autoreleasepool {
                dropNext=YES;
                [self _timerTick];
                dropNext=NO;
                
                CVOpenGLTextureCacheFlush(_textureCache, 0);
                                
            }
        }
}

- (void) stop
{
    @synchronized (timer)
    {
        [timer invalidate];
        timer=nil;
    }
}


#pragma mark - Texture methods

- (void)setCurrentTexture:(CVOpenGLTextureRef)texture
{
    if (_texture)
    {
        CVOpenGLTextureRelease(_texture);
    }
    _texture = texture;
    CVOpenGLTextureRetain(texture);
    


}
- (CVOpenGLBufferRef)currentTexture
{
    return _texture;
}


- (CVOpenGLTextureRef)createNewTextureFromBuffer: (CVOpenGLBufferRef) pixelBuffer
{
    CVOpenGLTextureRef textureOut;
    CVReturn theError ;
    
    if (!_textureCache)    
    {
        theError= CVOpenGLTextureCacheCreate(NULL, 0, 
                                             self.openGLContext.CGLContextObj, 
                                             self.pixelFormat.CGLPixelFormatObj, 
                                             0, &_textureCache);
        if (theError != kCVReturnSuccess)
        {
            //TODO: error handling
        }
        
    }
    theError= CVOpenGLTextureCacheCreateTextureFromImage ( NULL, 
                                                          _textureCache, 
                                                          pixelBuffer, 
                                                          NULL, 
                                                          &textureOut );
    if (theError != kCVReturnSuccess)
    {
        //TODO: error handling
    }

    return textureOut;
}




#pragma mark - Texture source protocol

- (GLuint) textureName
{
    return CVOpenGLTextureGetName(_texture);     
}

- (NSSize) textureSize
{
    GLfloat lowerLeft[2];
    GLfloat lowerRight[2];
    GLfloat upperRight[2];
    GLfloat upperLeft[2];
    CVOpenGLTextureGetCleanTexCoords(_texture, lowerLeft, lowerRight, upperRight, upperLeft);
    
    return NSMakeSize(abs(lowerLeft[0] - upperRight[0]), abs(lowerLeft[1] - upperRight[1]));
};

- (void)lockTexture
{
    CGLLockContext(_openGLContext.CGLContextObj);
}
- (void)unlockTexture
{
    CGLUnlockContext(_openGLContext.CGLContextObj);    
}


#pragma mark -Serialization
- (NSDictionary *)dictionaryRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.name, @"name",
            self.fps, @"fps",
            nil];
}



@end
