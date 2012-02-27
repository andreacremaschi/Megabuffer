//
//  MBWindowController.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBGLView.h"
#import "MBMarkersView.h"

@class MBGLView, MBOSCPropertyBindingController;
@interface MBWindowController : NSWindowController <MBGLViewFrameSource> {
    __unsafe_unretained MBMarkersView *markersView;
    __unsafe_unretained NSView *syphonSourceViewContainer;
    NSViewController *syphonSourceViewController;
    NSView *oscButtonAccessoryView;
}


// Outlets
@property (strong, readonly, nonatomic) IBOutlet NSArray *syphonAvailableApplications;
@property (strong, readonly, nonatomic) IBOutlet NSArray *syphonAvailableServerForCurrentApplication;
@property (unsafe_unretained) IBOutlet MBMarkersView *markersView;
@property (unsafe_unretained) IBOutlet NSView *syphonSourceViewContainer;
@property (strong) IBOutlet NSViewController *syphonSourceViewController;
@property (strong) IBOutlet NSView *oscButtonAccessoryView;

// Properties
@property (unsafe_unretained) IBOutlet NSArrayController *availableServersController;
@property (unsafe_unretained) IBOutlet MBGLView *liveInputGLView;
@property (unsafe_unretained) IBOutlet MBGLView *bufferOutputGLView;
@property int rateSpeedSelection;
@property NSTimeInterval curTime;
@property (strong,nonatomic) NSNumber *reverseAutoScrubTarget;
//@property double autoScrubTarget;

@property (readonly,nonatomic) MBOSCPropertyBindingController *bindingController;


// Actions
- (IBAction)addMarkerToNextFrame:(id)sender;
- (IBAction)prevMarker:(id)sender;
- (IBAction)nextMarker:(id)sender;
- (IBAction)setSpeedButton:(id)sender;
- (IBAction)setDelayButton:(id)sender;
- (IBAction)autoScrubButton:(id)sender;

@end
