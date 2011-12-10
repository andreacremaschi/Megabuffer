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
}
@end


#pragma mark - @implementation
@implementation MBBufferObject
@synthesize syphonIn;
@synthesize syphonOut;
@synthesize recording;
@synthesize rate;
@synthesize markers;
@synthesize delay;
@synthesize scrubMode;
@synthesize syInServerName;
@synthesize syInApplicationName;
@synthesize bufferSize;
@synthesize openGLContext;
@synthesize frameStack;

- (id)init
{
    self = [super init];
    if (self)
    {
        markers = [NSMutableArray array];
        bufferSize = 250; //10 secondi a 25 fps
        _frameSize = NSMakeSize(0,0);
        recording = true;
    }
    return self;
}


-(id)initWithOpenGLContext: (NSOpenGLContext *)context
{
    self = [self init];
    if (self)
    {
        openGLContext = context;
    }
    return self;

}

-(void)dealloc 
{
    syphonIn     = nil;
    syphonOut    = nil;
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

#pragma mark - Graphical stuff init

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
	
	//Use 'texture' to get texture target/id, texture bind, render to quad etc.. 
	GLenum target = GL_TEXTURE_RECTANGLE_ARB;
	GLint name = texture;		
	{
		glEnable(target);
		glBindTexture(target, name);
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
		
        
        //Get pixel buffer from pool
        CVPixelBufferRef pixelBuffer;
        CVReturn theError = CVOpenGLBufferPoolCreateOpenGLBuffer (kCFAllocatorDefault, _bufferPool, &pixelBuffer);
        if(theError) {
            NSLog(@"CVOpenGLBufferPoolCreateOpenGLBuffer() failed with error %i", theError);
            return;
        }	
        
        theError = CVOpenGLBufferAttach(pixelBuffer, 
                                        [openGLContext CGLContextObj], 
                                        0, 0, 
                                        [openGLContext currentVirtualScreen]);
        if (theError)	{
            NSLog(@"CVOpenGLBufferAttach() failed with error %i", theError);
            return;
        }
        
        // è arrivato un nuovo frame? siamo in record mode? bisogna farne una copia e conservarla!         
        CIImage *ciImage = [CIImage imageWithCVImageBuffer: pixelBuffer];
        [frameStack push: ciImage];
        
		CVOpenGLBufferRelease(pixelBuffer);		
	}
	
    

    return;
}

@end
