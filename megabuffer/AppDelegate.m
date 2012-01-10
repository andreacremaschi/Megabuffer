//
//  AppDelegate.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "SyphonLibraryController.h"

@implementation AppDelegate
@synthesize syphonLibraryPanel;

-(void)dealloc
{
    syphonLibraryPanel = nil;
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification 
{
    [self.syphonLibraryPanel.window makeKeyAndOrderFront: self];
}

@end
