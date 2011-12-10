//
//  MBWindowController.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBWindowController : NSWindowController
@property (strong, nonatomic) NSArray *selectedServerDescriptions;

@property (assign) IBOutlet NSArrayController *availableServersController;
@property (unsafe_unretained) IBOutlet NSOpenGLView *liveInputGLView;

@end
