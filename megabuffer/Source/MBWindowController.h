//
//  MBWindowController.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBGLView.h"

@class MBGLView;
@interface MBWindowController : NSWindowController <MBGLViewFrameSource>
@property (strong, nonatomic) NSArray *selectedServerDescriptions;

@property (assign) IBOutlet NSArrayController *availableServersController;
@property (unsafe_unretained) IBOutlet MBGLView *liveInputGLView;
@property (unsafe_unretained) IBOutlet MBGLView *bufferOutputGLView;
@property int rateSpeedSelection;


- (IBAction)addMarkerToNextFrame:(id)sender;
- (IBAction)prevMarker:(id)sender;
- (IBAction)nextMarker:(id)sender;

@end
