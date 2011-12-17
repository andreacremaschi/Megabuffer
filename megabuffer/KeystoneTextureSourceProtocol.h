//
//  KeystoneTextureSourceProtocol.h
//  Keystone
//
//  Created by Andrea Cremaschi on 03/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KeystoneTextureSourceProtocol <NSObject>

- (GLuint) textureName;
- (NSSize) textureSize;

- (void)lockTexture;
- (void)unlockTexture;

- (NSTimeInterval)currentFrameTimeStamp;

@end
