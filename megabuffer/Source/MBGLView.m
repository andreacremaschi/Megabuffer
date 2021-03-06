//
//  MBGLView.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBGLView.h"
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/CGLMacro.h>

#pragma mark - MBGLView extension @interface
@interface MBGLView () {

@private
    CVDisplayLinkRef        _displayLink;
    CGDirectDisplayID mainViewDisplayID;
    CIContext *_ciContext;
    bool _needsRebuild;
    NSTimeInterval lastFrameDrawnTimestamp;
}
- (CVReturn)displayFrame:(const CVTimeStamp *)timeStamp;

@end


#pragma mark - CoreVideo display link callback

CVReturn MyDisplayLinkCallback (
                                CVDisplayLinkRef displayLink,
                                const CVTimeStamp *inNow,
                                const CVTimeStamp *inOutputTime,
                                CVOptionFlags flagsIn,
                                CVOptionFlags *flagsOut,
                                void *displayLinkContext)
{
    CVReturn error =
    [(__bridge MBGLView*) displayLinkContext displayFrame:inOutputTime];
    return error;
}


#pragma mark - MBGLView @implementation
@implementation MBGLView
@synthesize frameSource;


#pragma mark - Initialization and dealloc

- (void)prepareOpenGL
{
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
    
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(_displayLink, &MyDisplayLinkCallback, (__bridge void*)self);
    
    // Set the display link for the current renderer
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, cgl_ctx, cglPixelFormat);

    //inizializza cicontext
    CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB ();
    _ciContext = [CIContext contextWithCGLContext: self.openGLContext.CGLContextObj 
                                      pixelFormat: self.pixelFormat.CGLPixelFormatObj
                                       colorSpace: myColorSpace
                                          options: nil];
    CGColorSpaceRelease(myColorSpace);

    // Activate the display link
    CVDisplayLinkStart(_displayLink);
    
    // disable unused state variabled
    
    glDisable(GL_DITHER);
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_FOG);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_DEPTH_TEST);
    glPixelZoom(1.0,1.0);
    
        _needsRebuild = YES;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
      CVDisplayLinkRelease(_displayLink);
}

- (void)reshape
{
	_needsRebuild = YES;
	[super reshape];
}

- (void)update
{
	// Thread-safe update
	CGLLockContext([[self openGLContext] CGLContextObj]);
	[super update];
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

#pragma mark - Methods
- (void)windowChangedScreen:(NSNotification*)inNotification
{
    NSWindow *window = self.window;
    CGDirectDisplayID displayID = (CGDirectDisplayID)[[[[window screen]
                                                        deviceDescription] objectForKey:@"NSScreenNumber"] intValue];
    if((displayID != 0) && (mainViewDisplayID != displayID))
    {
        CVDisplayLinkSetCurrentCGDisplay(_displayLink, displayID);
        mainViewDisplayID = displayID;
    }
}


- (void)drawRect:(NSRect)dirtyRect 
{	
	id <KeystoneTextureSourceProtocol> textureSource = self.frameSource;
	
	CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
	
	CGLLockContext(cgl_ctx);
	
	[textureSource lockTexture];
    
	NSRect frame = self.frame;
	
    // TODO: ottimizzare!
	/*if (_needsRebuild)
	{*/		
		
		// Setup OpenGL states
		glViewport(0, 0, frame.size.width, frame.size.height);
		
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(0.0, frame.size.width, 0.0, frame.size.height, -1, 1);
		
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		
		glTranslated(frame.size.width * 0.5, frame.size.height * 0.5, 0.0);
        
		[[self openGLContext] update];
		
	/*	_needsRebuild = NO;
	}*/
	
	// Draw our renderer's texture
    
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	if (textureSource.textureName != 0)
	{
		glEnable(GL_TEXTURE_RECTANGLE_EXT);
		
		glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureSource.textureName);
		
		NSSize textureSize = textureSource.textureSize;
		
		glColor4f(1.0, 1.0, 1.0, 1.0);
		
		NSSize scaled;
		float wr = textureSize.width / frame.size.width;
		float hr = textureSize.height / frame.size.height;
		float ratio;
		ratio = (hr < wr ? wr : hr);
		scaled = NSMakeSize((textureSize.width / ratio), (textureSize.height / ratio));
		
		GLfloat tex_coords[] = 
		{
			0.0,	0.0,
			textureSize.width,	0.0,
			textureSize.width,	textureSize.height,
			0.0,	textureSize.height
		};
		
		float halfw = scaled.width * 0.5;
		float halfh = scaled.height * 0.5;
		
		GLfloat verts[] = 
		{
			-halfw, -halfh,
			halfw, -halfh,
			halfw, halfh,
			-halfw, halfh
		};
        
		glEnableClientState( GL_TEXTURE_COORD_ARRAY );
		glTexCoordPointer(2, GL_FLOAT, 0, tex_coords );
		glEnableClientState(GL_VERTEX_ARRAY);
		glVertexPointer(2, GL_FLOAT, 0, verts );
		glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );
		glDisableClientState( GL_TEXTURE_COORD_ARRAY );
		glDisableClientState(GL_VERTEX_ARRAY);
        glFlush();
	}
    
	[[self openGLContext] flushBuffer];
    
	[textureSource unlockTexture];
    
	CGLUnlockContext(cgl_ctx);
}

/*
-(void)drawRect:(NSRect)dirtyRect
{

    CIImage *imageToDraw = [frameSource GLView: self wantsFrameWithOptions: nil];
    
    NSRect frame = self.frame;
	
    CGLContextObj cgl_ctx = self.openGLContext.CGLContextObj;
	CGLLockContext(cgl_ctx);
	if (_needsRebuild)
	{
		// Setup OpenGL states
		glViewport(0, 0, frame.size.width, frame.size.height);
		
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(0.0, frame.size.width, 0.0, frame.size.height, -1, 1);
		
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		
		glTranslated(frame.size.width * 0.5, frame.size.height * 0.5, 0.0);
        

        glClearColor(0.2,0.2,0.2,1.0); 
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        [[self openGLContext] update];
		
		_needsRebuild = NO;
	}

    float aspectRatio = imageToDraw.extent.size.width / imageToDraw.extent.size.height;
    CGRect scaledRect = CGRectMake(-frame.size.width*0.5, -frame.size.width / aspectRatio *0.5, frame.size.width,  frame.size.width / aspectRatio);
    
    [_ciContext drawImage:imageToDraw inRect:scaledRect fromRect:[imageToDraw extent]];

    
            glFlush();
    
    //[[self openGLContext] flushBuffer];
    CGLUnlockContext(cgl_ctx);
}*/


- (CVReturn)displayFrame: (const CVTimeStamp *)timeStamp
{
    @autoreleasepool {
        id <KeystoneTextureSourceProtocol> textureSource = self.frameSource;
        NSTimeInterval curFrameTime = [textureSource currentFrameTimeStamp];
        if (curFrameTime != lastFrameDrawnTimestamp)
        {
            [self drawRect:NSZeroRect];
            lastFrameDrawnTimestamp = curFrameTime;
        }
/*        else
            NSLog(@"%@ skips frame.", self);*/
    }
    return kCVReturnSuccess;
}

- (void) startDisplayLink
{
    CVDisplayLinkStart(_displayLink);
}

- (void) stopDisplayLink
{
    CVDisplayLinkStop(_displayLink);    
}
@end
