//
//  MBScrubberObject.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBScrubberObject.h"
#import <OpenGL/CGLMacro.h>

#import "MBBufferObject.h"
#import "NSMutableStack.h"

@interface MBScrubberObject () {
    bool needsRebuild;
    GLuint _fbo;
    GLuint _depthBuffer;
    CVOpenGLTextureRef _texture;
    CVOpenGLTextureCacheRef _textureCache;
    CGSize _currentSize;
}
- (void)timerFire:(NSTimer*)theTimer;


@end

@implementation MBScrubberObject
@synthesize delay;
@synthesize scrubMode;
@synthesize rate;
@synthesize syphonOut;
@synthesize buffer;
@synthesize timer;
@synthesize _pixelFormat;
@synthesize _openGLContext;
@synthesize serverName;

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self)
    {
        NSError *error;
        needsRebuild=true;

        // Kick off a new Thread
        [NSThread detachNewThreadSelector:@selector(createTimer) toTarget:self withObject:nil];

        [self initOpenGLContextWithSharedContext: nil error: &error];
        _texture=0;
    
    }
    return self;
}


-(void)dealloc 
{
    [timer invalidate];
    CVOpenGLTextureRelease(_texture);
    timer=nil;
    buffer=nil;
    syphonOut = nil;
}


#pragma mark - Timer creation
- (void) createTimer{
    @autoreleasepool {
        // Create a time for the thread
        timer = [NSTimer timerWithTimeInterval:1.0/30.0
                                        target:self 
                                      selector:@selector(timerFire:)
                                      userInfo:nil repeats:YES];
        // Add the timer to the run loop
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
	
    }        
}

#pragma mark - Server creation

- (void)setServerName:(NSString *)object
{
    @synchronized(self)
    {
        syphonOut = [[SyphonServer alloc] initWithName:	 object
                                               context:		_openGLContext.CGLContextObj
                                               options:		nil]; 
    }
    serverName=object;
    
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



#pragma mark - Timer
- (void)timerFire:(NSTimer*)theTimer
{
    @autoreleasepool {
        
    
    @synchronized(timer)
    {
        if ((!timer.isValid) || (self.buffer.frameStack.count ==0))
            return;
        //CIImage *image = [self currentFrame];
        int scrubPosition=round(delay/12.0*250.0);
        if (scrubPosition>=249) scrubPosition=249;
        NSDictionary *imageDict = [self.buffer.frameStack objectAtIndex: scrubPosition];
        if (!imageDict) return;

        
        CVPixelBufferRef pixelBuffer = [[imageDict valueForKey: @"image"] pointerValue];
        
        NSDictionary *attributesDict =  (__bridge  NSDictionary *)CVOpenGLBufferGetAttributes(pixelBuffer);
        
        //CGRect frame = image.extent;
        CGRect frame = CGRectMake(0.0, 0.0, [[attributesDict valueForKey:@"Width"] doubleValue], [[attributesDict valueForKey:@"Height"] doubleValue]) ;
        if (CGRectEqualToRect(frame, CGRectZero)) return;

        CVPixelBufferRetain(pixelBuffer);
        
        CGLContextObj cgl_ctx = [_openGLContext CGLContextObj];
        CGLLockContext(_openGLContext.CGLContextObj);

        CVOpenGLTextureRef textureOut;
                    CVReturn theError ;
        
        if (!_textureCache)    
        {
            theError= CVOpenGLTextureCacheCreate(NULL, 0, 
                                                 cgl_ctx, [_pixelFormat CGLPixelFormatObj], 
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

        
        GLenum target = CVOpenGLTextureGetTarget(textureOut);
        GLint name = CVOpenGLTextureGetName(textureOut);     
   
        
        // publish our frame to our server. 
        @synchronized(self)
        {
            if (nil == syphonOut)
                syphonOut = [[SyphonServer alloc] initWithName:	@"scrubber1"
                                                       context:		_openGLContext.CGLContextObj
                                                       options:		nil];        
            [syphonOut publishFrameTexture: name
                             textureTarget: target
                               imageRegion: NSMakeRect(0, 0, frame.size.width, frame.size.height)
                         textureDimensions: frame.size
                                   flipped: NO];
        }
        // let the renderer resume drawing
        //    [theRenderer unlockTexture];

        if (_texture)
            CVOpenGLTextureRelease(_texture);
        _texture = textureOut;
        
        CVOpenGLTextureCacheFlush(_textureCache, 0);

    /*    // Restore OpenGL states
        glMatrixMode(GL_MODELVIEW);
        glPopMatrix();
        
        glMatrixMode(GL_PROJECTION);
        glPopMatrix();*/
		
        // back to main rendering.
        //glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
        CGLUnlockContext(_openGLContext.CGLContextObj);
        
        CVPixelBufferRelease(pixelBuffer);
        
    }
        }
}


#pragma mark - Methods

- (CIImage *)currentFrame
{
    return buffer? [buffer ciImageAtTime: 0] : nil;
}

- (void) stop
{
    @synchronized (timer)
    {
    [timer invalidate];
    }
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


@end
