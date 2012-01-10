//
//  SyphonSourceViewController.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SyphonSourceViewController : NSViewController

// Properties
@property (strong, nonatomic) NSDictionary *serverDescription;

// Actions
- (IBAction)resetSelectedServer:(id)sender;
@end
