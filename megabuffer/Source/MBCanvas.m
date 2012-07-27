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

@end

@implementation MBCanvas
@synthesize pixelFormat = _pixelFormat;
@synthesize openGLContext = _openGLContext;
@synthesize currentFrameTimeStamp;

- (id)init
{
    self = [super init];
    if (self)
    {       
        
        _texture=0;

    }
    return self;
}

-(void)dealloc 
{

    CVOpenGLTextureRelease(_texture);
}



#pragma mark - Attributes

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

-(void)flushTextureCache
{
    CVOpenGLTextureCacheFlush(_textureCache, 0);
}

#pragma mark -Serialization
- (NSDictionary *)dictionaryRepresentation
{
    return [NSDictionary dictionary];
}



@end
