//
//  MBBufferObject.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceSyphon.h"



@class SourceSyphon,NSMutableStack;
@interface MBBufferObject : NSObject <TextureSourceDelegate>

@property (strong) SourceSyphon* syphonIn;
@property (strong) NSString *syInServerName;
@property (strong) NSString *syInApplicationName;

@property uint bufferSize;

@property (strong) NSMutableArray * markers;
@property bool recording;

@property (strong, nonatomic) NSMutableStack * frameStack;

-(id)initWithOpenGLContext: (NSOpenGLContext *)context;

-(void)setServerDescription:(NSDictionary *)serverDescription;

- (CIImage *)imageAtTime: (NSTimeInterval) time;
@end
