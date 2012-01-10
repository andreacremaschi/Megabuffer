//
//  SyphonLibraryController.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SyphonLibraryController.h"
#import "SyphonSourceView.h"
#import <Syphon/Syphon.h>

@implementation SyphonLibraryController
@synthesize availableServersController;
@synthesize syphonTableView;

#pragma mark - Initialization

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
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
    
    // registrati per il drag and drop
    [syphonTableView registerForDraggedTypes: [NSArray arrayWithObjects: serverDescriptionPBoardType, nil]];
    
}

-(NSString *)windowNibName
{
    return @"SyphonLibrary";
}

#pragma mark - Table view drag and drop

-(BOOL)tableView: (NSTableView *)tableView 
writeRowsWithIndexes: (NSIndexSet *)rowIndexes 
    toPasteboard: (NSPasteboard *)pboard
{
    if (rowIndexes.count!=1) return NO;
    
    id serverDescrDict = [[[availableServersController arrangedObjects] objectsAtIndexes: rowIndexes] lastObject];
    NSData *data = [NSArchiver archivedDataWithRootObject: serverDescrDict];
    
    [pboard declareTypes: [NSArray arrayWithObject: serverDescriptionPBoardType]
                   owner: nil];
    [pboard setData: data forType: serverDescriptionPBoardType];
    return YES;
}


@end
