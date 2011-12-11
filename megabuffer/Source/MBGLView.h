//
//  MBGLView.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@protocol MBGLViewFrameSource;

@interface MBGLView : NSOpenGLView
@property (strong, nonatomic) NSObject <MBGLViewFrameSource> *frameSource;
@end

@protocol MBGLViewFrameSource
- (CIImage*)GLView: (NSOpenGLView *)view wantsFrameWithOptions: (NSDictionary *)dict;
@end