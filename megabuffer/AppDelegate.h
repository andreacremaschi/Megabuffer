//
//  AppDelegate.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SyphonLibraryController;
@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) IBOutlet SyphonLibraryController * syphonLibraryPanel;
@end
