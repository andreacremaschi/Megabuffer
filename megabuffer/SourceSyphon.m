//
//  SourceSyphon.m
//  Keystone
//
//  Created by Andrea Cremaschi on 30/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SourceSyphon.h"

@implementation SourceSyphon
@synthesize syClient;
@synthesize srcDescription;
@synthesize openGLContext;
@synthesize pixelFormat;
@synthesize delegate;


#pragma mark KeystoneTextureSource protocol implementation
- (SourceSyphon *) initWithDescription:(NSDictionary *)descr {
  
    self = [super init];
    if (self)
    {
    
        fpsStart = [NSDate timeIntervalSinceReferenceDate];
        textureSourceStart = [NSDate timeIntervalSinceReferenceDate]; 
        fpsCount = 0;
        FPS = 0;
        
        
        NSDictionary *description = [descr copy];
        srcDescription = description ;
        
        syClient= [[SyphonClient alloc] initWithServerDescription:description options:nil newFrameHandler:^(SyphonClient *client) {
            // This gets called whenever the client receives a new frame.
            
            // The new-frame handler could be called from any thread, but because we update our UI we have
            // to do this on the main thread.
            
            
            // attenzione: questo block non viene mai rilasciato. perché diavolo?????
            // TODO: fix
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                // First we track our framerate...
                fpsCount++;
                float elapsed = [NSDate timeIntervalSinceReferenceDate] - fpsStart;
                if (elapsed > 1.0)
                {
                    FPS = ceilf(fpsCount / elapsed);
                    fpsStart = [NSDate timeIntervalSinceReferenceDate];
                    fpsCount = 0;
                }
                
                // ...then we check to see if our dimensions display or window shape needs to be updated
                SyphonImage *frame = [client newFrameImageForContext: [self.openGLContext CGLContextObj]];
                
                NSSize imageSize = frame.textureSize;
                
                 BOOL changed = NO;
                 if (frameWidth != imageSize.width)
                 {
                     changed = YES;
                     frameWidth = imageSize.width;
                 }
                 if (frameHeight != imageSize.height)
                 {
                     changed = YES;
                     frameHeight = imageSize.height;
                 }

             if (changed)
             {

             /*[[glView window] setContentAspectRatio:imageSize];
             [self resizeWindowForCurrentVideo];*/
             }
                NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
                if ((self.delegate) && ([self.delegate respondsToSelector: @selector(syphonSource:didReceiveNewFrameOnTime:)]))
                    [self.delegate syphonSource: self 
                       didReceiveNewFrameOnTime: now-textureSourceStart ];
                
                
             // ...then mark our view as needing display, it will get the frame when it's ready to draw
             //[glView setNeedsDisplay:YES];
             }];
        }];
        
    }

    
    // Our view uses the client to draw, so keep it up to date
    //  [glView setSyClient:syClient];
    
    // If we have a client we do nothing - wait until it outputs a frame
    
    // Otherwise clear the view
    /*  if (syClient == nil)
     {
     self.frameWidth = 0;
     self.frameHeight = 0;
     [glView setNeedsDisplay:YES];
     }*/
    //   }
    return self;
}


#pragma mark - TextureSource protocol imlpementation
- (GLuint) textureName 
{   return _texture; }

- (NSSize) textureSize
{ return NSMakeSize(frameWidth, frameHeight); }
@end
