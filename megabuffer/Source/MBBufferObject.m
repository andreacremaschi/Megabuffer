//
//  MBBufferObject.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBBufferObject.h"
#import "SourceSyphon.h"
#import "NSMutableStack.h"

#import <Syphon/Syphon.h>
#import <OpenGL/CGLMacro.h>

#pragma mark - Extension @interface
@interface MBBufferObject ()
{
    CVOpenGLBufferPoolRef _bufferPool;    
    NSSize _frameSize;
    SyphonImage *_image;
    CVOpenGLTextureRef _texture;
    CVOpenGLTextureCacheRef _textureCache;
}


- (bool)initOpenGLContextWithSharedContext: (NSOpenGLContext*)sharedContext error: (NSError **)error;

@end


#pragma mark - @implementation
@implementation MBBufferObject
@synthesize syphonIn;

@synthesize recording;

@synthesize markers;

@synthesize syInServerName;
@synthesize syInApplicationName;
@synthesize bufferSize;
@synthesize openGLContext;
@synthesize pixelFormat;
@synthesize frameStack;

- (id)init
{
    self = [super init];
    if (self)
    {
        markers = [NSMutableArray array];
        bufferSize = 250; //10 secondi a 25 fps
        _frameSize = NSMakeSize(0,0);
        _texture=nil;
        recording = true;
        frameStack = [[NSMutableStack alloc] init];
        NSError *error;
        if (! [self initOpenGLContextWithSharedContext: nil error: &error]) 
        {
            NSLog(@"Error: couldn't init Opengl shared context.\n%@", error);
            self = nil;
            return nil;
        }
    }
    return self;
}


-(id)initWithOpenGLContext: (NSOpenGLContext *)context
{
    self = [self init];
    if (self)
    {   NSError *error;
        if (! [self initOpenGLContextWithSharedContext: context error: &error]) 
        {
            NSLog(@"Error: couldn't init Opengl shared context.\n%@", error);
            self = nil;
            return nil;
        }
    }
    return self;

}

-(void)dealloc 
{
    syphonIn.delegate     = nil;
    syphonIn     = nil;
}

#pragma mark - Accessors

-(void)setServerDescription:(NSDictionary *)serverDescription   
{
    if ([[serverDescription allKeys] containsObject: SyphonServerDescriptionNameKey] &&
        [[serverDescription allKeys] containsObject: SyphonServerDescriptionAppNameKey])
    {
        syInServerName = [serverDescription valueForKey: SyphonServerDescriptionNameKey];
        syInApplicationName = [serverDescription valueForKey: SyphonServerDescriptionAppNameKey];
        syphonIn = [[SourceSyphon alloc] initWithDescription: serverDescription];
        syphonIn.delegate = self;
    }
}

- (CIImage *)ciImageAtTime: (NSTimeInterval) time
{
    if (frameStack.count>0)
    {
        CVPixelBufferRef oldBuffer = [[[frameStack objectAtIndex: 0] valueForKey: @"image"] pointerValue];

        return [CIImage imageWithCVImageBuffer:oldBuffer];
    }
    else return [CIImage emptyImage];
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
	
	openGLContext = newOpenGLContext ;	
	pixelFormat = newPixelFormat;
	
	/*
	 // setup OpenGL multithreading
     CGLError err = 0;
     CGLContextObj ctx = [newOpenGLContext CGLContextObj];
     
     // Enable the multithreading
     err =  CGLEnable( ctx, kCGLCEMPEngine);
     
     if (err != kCGLNoError )
     {
     // Multithreaded execution may not be available
     // Insert your code to take appropriate action
     }
     */
	return true;
	
}


- (bool)initCVOpenGLBufferPoolWithSize: (NSSize) size
								 error: (NSError **)error {
    
	CVReturn						theError;

    // destroy old bufferpool
    if(_bufferPool)
        CVOpenGLBufferPoolRelease(_bufferPool);
    
	//Create buffer pool
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    //	[attributes setObject:[NSNumber numberWithUnsignedInt:15] forKey:(NSString*)kCVOpenGLBufferPoolMinimumBufferCountKey];
    //	[attributes setObject:[NSNumber numberWithUnsignedInt:0.3] forKey:(NSString*)kCVOpenGLBufferPoolMaximumBufferAgeKey];
	[attributes setValue:[NSNumber numberWithInt:size.width] forKey:(NSString*)kCVOpenGLBufferWidth];
	[attributes setValue:[NSNumber numberWithInt:size.height] forKey:(NSString*)kCVOpenGLBufferHeight];
	
    CFDictionaryRef cfDict = CFBridgingRetain(attributes);
	theError = CVOpenGLBufferPoolCreate(kCFAllocatorDefault, NULL, cfDict, &_bufferPool);
    CFBridgingRelease(cfDict);
    
	if(theError) {
		NSLog(@"CVPixelBufferPoolCreate() failed with error %i", theError);
		return false;
	}
	//CVOpenGLBufferPoolRetain(_bufferPool);
        
	return (theError == kCVReturnSuccess);
	
}


#pragma mark - TextureSourceDelegate implementation

-(void)syphonSource:(SourceSyphon *)sourceSyphon didReceiveNewFrameOnTime:(NSTimeInterval)time
{
    
    if (!openGLContext) return;
    if (!self.recording) return; // non in record mode: ignora il nuovo frame
    SyphonClient *syClient = sourceSyphon.syClient;
    
    [self lockTexture];
    SyphonImage *image = [syClient newFrameImageForContext: openGLContext.CGLContextObj];
	CGLContextObj cgl_ctx = openGLContext.CGLContextObj;
    
	GLuint texture = [image textureName];
	NSSize imageSize = [image textureSize];
	
	BOOL changed = NO;
	if ((_frameSize.width != imageSize.width) || 
		(_frameSize.height != imageSize.height))
	{
		changed = YES;
		_frameSize.width = imageSize.width;
		_frameSize.height = imageSize.height;
		[self initCVOpenGLBufferPoolWithSize: imageSize error: nil];
	}
	
	if (changed)
	{		
		glViewport(0, 0, imageSize.width, imageSize.height);
		
		glMatrixMode(GL_MODELVIEW);    // select the modelview matrix
		glLoadIdentity();              // reset it
		
		glMatrixMode(GL_PROJECTION);   // select the projection matrix
		glLoadIdentity();              // reset it
		
		glOrtho(0, 0, imageSize.width, imageSize.height, -1.0, 1.0);// define a 2-D orthographic projection matrix
	}
	
    //Get pixel buffer from pool
    CVPixelBufferRef pixelBuffer;
    CVReturn theError = CVOpenGLBufferPoolCreateOpenGLBuffer (kCFAllocatorDefault, _bufferPool, &pixelBuffer);
    if(theError) {
        NSLog(@"CVOpenGLBufferPoolCreateOpenGLBuffer() failed with error %i", theError);
        [self unlockTexture];
        return;
    }	
    
    theError = CVOpenGLBufferAttach(pixelBuffer, 
                                    [openGLContext CGLContextObj], 
                                    0, 0, 
                                    [openGLContext currentVirtualScreen]);
    if (theError)	{
        NSLog(@"CVOpenGLBufferAttach() failed with error %i", theError);
        [self unlockTexture];
        return;
    }
    
	//Use 'texture' to get texture target/id, texture bind, render to quad etc.. 
	GLenum target = GL_TEXTURE_RECTANGLE_ARB;
	GLint name = texture;		
	{
		glEnable(target);
		glBindTexture(target, name);
        
        //glClearColor(1.0,0.0,0.0,1.0); 
        //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		glBegin(GL_QUADS);
		{
			glTexCoord2f( imageSize.width, 0.0f );				glVertex2f(  1.0f, -1.0f );
			glTexCoord2f( 0.0f, 0.0f );							glVertex2f( -1.0f, -1.0f );
			glTexCoord2f( 0.0f, imageSize.height );				glVertex2f( -1.0f, 1.0f );
			glTexCoord2f( imageSize.width, imageSize.height );	glVertex2f(  1.0f, 1.0f );
		}
		glEnd();
        
		glFlush();
		glDisable(target);
		
        
        
        // è arrivato un nuovo frame? siamo in record mode? bisogna farne una copia e conservarla!         
//        CIImage *ciImage = [CIImage imageWithCVImageBuffer: pixelBuffer];
            NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSValue valueWithPointer: pixelBuffer], @"image",
                                     [NSNumber numberWithDouble:time], @"time",
                                     nil];
        
        NSDictionary *oldDict = [frameStack push: newDict];
        if (oldDict)
        {
            CVPixelBufferRef oldBuffer = [[oldDict valueForKey: @"image"] pointerValue];
            CVOpenGLBufferRelease(oldBuffer);
        }
        

        
        // Create the duplicate texture
        CVOpenGLTextureRef textureOut;
        CVReturn theError ;
        
        if (!_textureCache)
        {
            theError= CVOpenGLTextureCacheCreate(NULL, 0, 
                                                 cgl_ctx, [pixelFormat CGLPixelFormatObj], 
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

        
        if (_texture)
            CVOpenGLTextureRelease(_texture);
        _texture = textureOut;
        
        CVOpenGLTextureCacheFlush(_textureCache, 0);
        
      /*  theError = CVOpenGLBufferAttach(0, 
                                        [openGLContext CGLContextObj], 
                                        0, 0, 
                                        [openGLContext currentVirtualScreen]);*/
		//CVOpenGLBufferRelease(pixelBuffer);		
	}
	
    [self unlockTexture];


    return;
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
    CGLLockContext(openGLContext.CGLContextObj);
}
- (void)unlockTexture
{
    CGLUnlockContext(openGLContext.CGLContextObj);    
}



@end
