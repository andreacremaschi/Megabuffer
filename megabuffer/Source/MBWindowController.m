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
    [bDoc.buffer initOpenGLContextWithSharedContext: self.liveInputGLView.openGLContext error:nil];
    bDoc.scrubber.openGLContext = self.bufferOutputGLView.openGLContext;
    bDoc.scrubber.pixelFormat = self.bufferOutputGLView.pixelFormat;
    //TEMP
    
    liveInputGLView.frameSource=bDoc.buffer;
    bufferOutputGLView.frameSource=bDoc.scrubber;
    
    // ferma il display link quando la finestra perde il focus
    [[NSNotificationCenter defaultCenter] addObserver: liveInputGLView 
                                             selector: @selector(stopDisplayLink)
                                                 name: NSWindowDidResignMainNotification 
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: bufferOutputGLView 
                                             selector: @selector(stopDisplayLink)
                                                 name: NSWindowDidResignMainNotification 
                                               object: nil];

    // avvia il display link quando la finestra prende il focus 
    [[NSNotificationCenter defaultCenter] addObserver: liveInputGLView 
                                             selector: @selector(startDisplayLink)
                                                 name: NSWindowDidBecomeMainNotification 
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: bufferOutputGLView 
                                             selector: @selector(startDisplayLink)
                                                 name: NSWindowDidBecomeMainNotification 
                                               object: nil];
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

+ (NSSet *)keyPathsForValuesAffectingRateSpeedSelection
{
    return [NSSet setWithObject: @"document.scrubber.rate"];
}

- (int) rateSpeedSelection
{
     BDocument *bDoc=(BDocument *) self.document;
    int rate = [bDoc.scrubber.rate intValue];
    if ((rate ==0) ||(rate ==-2)||(rate ==-1)||(rate ==2)||(rate ==1))
        return rate;
    else
        return -3;
}

- (void) setRateSpeedSelection: (int)newRate
{
    BDocument *bDoc=(BDocument *) self.document;
    bDoc.scrubber.rate = [NSNumber numberWithInt: newRate] ;
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


#pragma mark - IBActions

- (IBAction)addMarkerToNextFrame:(id)sender
{
    BDocument *bDoc=(BDocument *) self.document;
    [bDoc.buffer addMarkerToNextFrame];
}

- (IBAction)prevMarker:(id)sender
{
    BDocument *bDoc=(BDocument *) self.document;
    [bDoc.scrubber gotoPreviousMarker];
}
- (IBAction)nextMarker:(id)sender
{
    BDocument *bDoc=(BDocument *) self.document;
    [bDoc.scrubber gotoNextMarker];
}
@end
