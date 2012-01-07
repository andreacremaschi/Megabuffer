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

#pragma mark - Initialization

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
    
    // tweak interfaccia
    self.window.backgroundColor = [NSColor darkGrayColor];
    
    
    
    // We use an NSArrayController to populate the menu of available servers
    // Here we bind its content to SyphonServerDirectory's servers array
    [availableServersController bind:@"contentArray" 
                            toObject: [SyphonServerDirectory sharedDirectory] 
                         withKeyPath:@"servers" 
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

#pragma mark - Accessors and KVO

+(NSSet *)keyPathsForValuesAffectingSyphonAvailableApplications 
{
    return [NSSet setWithObject: @"availableServersController.contentArray"];
}

+(NSSet *)keyPathsForValuesAffectingSyphonAvailableServerForCurrentApplication 
{
    return [NSSet setWithObject: @"document.buffer.syInServerName"];
}           

- (NSArray *)syphonAvailableApplications
{
    NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@",  SyphonServerDescriptionAppNameKey];
    NSArray *availableApps= [[[SyphonServerDirectory sharedDirectory] servers] valueForKeyPath: keyPath];
    return availableApps;
    
}

- (NSArray *)syphonAvailableServerForCurrentApplication
{
    BDocument *bDoc=(BDocument *) self.document;

    NSMutableArray *availableServers = [NSMutableArray array];

    NSString *selAppName = bDoc.buffer.syInApplicationName;
    for (NSDictionary *syServerDescr in [[SyphonServerDirectory sharedDirectory] servers])
    {
        if ([[syServerDescr objectForKey: SyphonServerDescriptionAppNameKey] isEqualToString: selAppName])
            [availableServers addObject: [syServerDescr objectForKey: SyphonServerDescriptionNameKey]];
    }
    return [availableServers copy];    
}

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

- (IBAction)setSpeedButton:(id)sender
{
    NSButton *button = (NSButton *)sender;
    double speed = button.tag;

    BDocument *bDoc=(BDocument *) self.document;
    [bDoc.scrubber setRate: [NSNumber numberWithDouble:speed]];
    
}

- (IBAction)setDelayButton:(id)sender
{
    NSMatrix *matrix = (NSMatrix *)sender;
    NSButtonCell *button =[matrix cellAtRow: matrix.selectedRow column:0];
    double delay = button.tag;
    
    BDocument *bDoc=(BDocument *) self.document;
    [bDoc.scrubber setDelay: [NSNumber numberWithDouble:delay]];
    
}

@end
