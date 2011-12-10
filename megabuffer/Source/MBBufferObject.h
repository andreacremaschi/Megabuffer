//
//  MBBufferObject.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceSyphon.h"

typedef enum {
    MBScrubMode_off,
    MBScrubMode_rate,
    MBScrubMode_speed
} scrubModes;

@class SourceSyphon,NSMutableStack;
@interface MBBufferObject : NSObject <TextureSourceDelegate>

@property (strong) SourceSyphon* syphonIn;
@property (strong) NSString *syInServerName;
@property (strong) NSString *syInApplicationName;

@property (strong) id syphonOut;

@property uint bufferSize;

@property (strong, nonatomic) NSOpenGLContext *openGLContext;

@property (strong) NSMutableArray * markers;
@property bool recording;
@property double rate;
@property double delay;
@property scrubModes scrubMode;

@property (strong, nonatomic) NSMutableStack * frameStack;

-(void)setServerDescription:(NSDictionary *)serverDescription;


@end
