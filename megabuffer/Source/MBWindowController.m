//
//  MBWindowController.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBWindowController.h"
#import "BDocument.h"
#import "MBBufferObject.h"
#import "MBScrubberObject.h"
#import "MBGLView.h"

#import <Syphon/Syphon.h>

@implementation MBWindowController
@synthesize availableServersController;
@synthesize liveInputGLView;
@synthesize bufferOutputGLView;
@synthesize selectedServerDescriptions;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(id)init   
{
    self = [self initWithWindowNibName:@"BDocument"];
    if (self) {
        // Initialization code here.
    }
    
    return self;    
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // We use an NSArrayController to populate the menu of available servers
    // Here we bind its content to SyphonServerDirectory's servers array
    [availableServersController bind:@"contentArray" 
                            toObject: [SyphonServerDirectory sharedDirectory] 
                         withKeyPath:@"servers" 
                             options:nil];
    
    // Slightly weird binding here, if anyone can neatly and non-weirdly improve on this then feel free...
    [self bind:@"selectedServerDescriptions" 
      toObject:availableServersController 
   withKeyPath:@"selectedObjects" 
       options:nil];

    BDocument *bDoc=(BDocument *) self.document;
    
    //TEMP
    [bDoc.buffer initWithOpenGLContext: self.liveInputGLView.openGLContext];
    bDoc.scrubber._openGLContext = self.bufferOutputGLView.openGLContext;
    bDoc.scrubber._pixelFormat = self.bufferOutputGLView.pixelFormat;
    //TEMP
    
    liveInputGLView.frameSource=bDoc.buffer;
    bufferOutputGLView.frameSource=bDoc.scrubber;
    
    
    
}

#pragma mark - Accessors
- (void)setSelectedServerDescriptions: (NSArray *)descriptions
{   
    NSDictionary *serverDescription = [descriptions lastObject];
    if (serverDescription)
    {
        // it will, since our only video input is Syphon server
            [[(BDocument *) self.document buffer] setServerDescription: serverDescription];
    }
}

#pragma mark - MBGLView protocol implementation

- (CIImage *)GLView:(NSOpenGLView *)view wantsFrameWithOptions:(NSDictionary *)dict 
{
    BDocument *bDocument = (BDocument*)self.document;
//    MBBufferObject *buffer = bDocument.buffer;
    MBScrubberObject *scrubber = bDocument.scrubber;
    if (scrubber)
        return [scrubber currentFrame] ;
    else
        return [CIImage emptyImage];
    
    
}

@end
