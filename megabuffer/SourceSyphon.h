//
//  SourceSyphon.h
//  Keystone
//
//  Created by Andrea Cremaschi on 30/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Syphon/Syphon.h>
#import "KeystoneTextureSourceProtocol.h"

@protocol TextureSourceDelegate;
@interface SourceSyphon : NSObject <KeystoneTextureSourceProtocol>
{
    SyphonClient*syClient;
    
    NSTimeInterval fpsStart;
    NSTimeInterval textureSourceStart;
	NSUInteger fpsCount;
    NSDictionary *srcDescription;
    NSUInteger FPS;
    NSOpenGLContext *openGLContext;
    NSUInteger frameWidth;
	NSUInteger frameHeight;
    GLuint _texture;
}

@property (readonly) SyphonClient *syClient; 

@property (strong, readonly, nonatomic) NSDictionary *srcDescription;
@property (strong, readonly, nonatomic ) NSOpenGLContext* openGLContext;
@property (strong, readonly, nonatomic) NSOpenGLPixelFormat* pixelFormat;

@property (unsafe_unretained, nonatomic) NSObject <TextureSourceDelegate>* delegate;

- (SourceSyphon *) initWithDescription:(NSDictionary *)description;

@end



@protocol TextureSourceDelegate
-(NSOpenGLContext*) openGLContext;
- (void) syphonSource: (SourceSyphon*)textureSource didReceiveNewFrameOnTime: (NSTimeInterval) time;
@end