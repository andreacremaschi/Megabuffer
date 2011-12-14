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
    GLuint _textureName;
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

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self)
    {
        NSError *error;
        needsRebuild=true;

        timer = [NSTimer timerWithTimeInterval:1.0/30.0
                                        target:self 
                                      selector:@selector(timerFire:)
                                      userInfo:nil repeats:YES];
        [self initOpenGLContextWithSharedContext: nil error: &error];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];

    
    }
    return self;
}


-(void)dealloc 
{
    [timer invalidate];
    timer=nil;
    buffer=nil;
    syphonOut = nil;
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

- (void) rebuildTextureWithSize: (CGSize) size
{
    GLuint oldTexture = _textureName;
    CGLContextObj cgl_ctx = [_openGLContext CGLContextObj];
    _currentSize=size;
    
    if(oldTexture)
    {
        glDeleteTextures(1, &oldTexture);
    }
    if(_fbo)
    {
        glDeleteFramebuffersEXT(1, &_fbo);
        _fbo = 0;
    }
    if(_depthBuffer)
    {
        glDeleteRenderbuffersEXT(1, &_depthBuffer);
        _depthBuffer = 0;
    }
    
    // texture / color attachment
    glGenTextures(1, &_textureName);
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, _textureName);
    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA8, _currentSize.width, _currentSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
    
    // depth buffer
   /* glGenRenderbuffersEXT(1, &_depthBuffer);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, _depthBuffer);
    glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, _currentSize.width, _currentSize.height);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0);
    
    // FBO and connect attachments
    glGenFramebuffersEXT(1, &_fbo);
    glBindFramebufferEXT(GL_FRAMEBUFFER, _fbo);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE_EXT, _textureName, 0);
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER_EXT, _depthBuffer);
    // Draw black so we have output if the renderer isn't loaded
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glBindFramebufferEXT(GL_FRAMEBUFFER, 0);
    
    GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER);
    if(status != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Megabuffer: OpenGL error %04X", status);
        glDeleteTextures(1, &_textureName);
        glDeleteFramebuffersEXT(1, &_fbo);
        glDeleteRenderbuffersEXT(1, &_depthBuffer);
        _textureName = 0;
        _fbo = 0;
        _depthBuffer = 0;
        CGLUnlockContext(cgl_ctx);
    }*/
    
    //		NSLog(@"created texture/FBO with size: %@", NSStringFromSize(_currentSize));
        
    
}

#pragma mark - Timer
- (void)timerFire:(NSTimer*)theTimer
{
    @synchronized(timer)
    {
        if ((!timer.isValid) || (self.buffer.frameStack.count ==0))
            return;
        //CIImage *image = [self currentFrame];
        NSDictionary *imageDict = [self.buffer.frameStack objectAtIndex: 0];
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
   
        
        // publish our frame to our server. We use the whole texture, but we could just publish a region of it
        if (nil == syphonOut)
            syphonOut = [[SyphonServer alloc] initWithName:	@"scrubber1"
                                                   context:		_openGLContext.CGLContextObj
                                                   options:		nil];        

        [syphonOut publishFrameTexture: name
                         textureTarget: target
                           imageRegion: NSMakeRect(0, 0, frame.size.width, frame.size.height)
                     textureDimensions: frame.size
                               flipped: NO];
        // let the renderer resume drawing
        //    [theRenderer unlockTexture];
        
        // Restore OpenGL states
        glMatrixMode(GL_MODELVIEW);
        glPopMatrix();
        
        glMatrixMode(GL_PROJECTION);
        glPopMatrix();
		
        // back to main rendering.
        //glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
        CGLUnlockContext(_openGLContext.CGLContextObj);
        
        CVPixelBufferRelease(pixelBuffer);
        
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
@end
