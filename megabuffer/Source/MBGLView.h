//
//  MBGLView.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "KeystoneTextureSourceProtocol.h"

@protocol MBGLViewFrameSource;

@interface MBGLView : NSOpenGLView
@property (strong, nonatomic) NSObject <KeystoneTextureSourceProtocol> *frameSource;

- (void) startDisplayLink;
- (void) stopDisplayLink;

@end

@protocol MBGLViewFrameSource
- (CIImage*)GLView: (NSOpenGLView *)view wantsFrameWithOptions: (NSDictionary *)dict;
@end