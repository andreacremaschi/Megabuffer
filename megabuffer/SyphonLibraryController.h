//
//  SyphonLibraryController.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SyphonLibraryController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
    __unsafe_unretained NSTableView *syphonTableView;
}


// Properties
@property (unsafe_unretained) IBOutlet NSArrayController *availableServersController;

// Outlets
@property (unsafe_unretained) IBOutlet NSTableView *syphonTableView;

@end
