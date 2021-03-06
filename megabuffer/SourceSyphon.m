//
//  SourceSyphon.m
//  Keystone
//
//  Created by Andrea Cremaschi on 30/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SourceSyphon.h"
#import <Syphon/Syphon.h>

#pragma mark - Private interface

@interface SourceSyphon ()

@property (strong) NSString *waitingForServerObserver;
@property (strong) NSString *validPropertyObserver;
- (void) waitForServer;
- (void) setupSyphonInWithDescription: (NSDictionary *)syphonDescription;
- (NSDictionary *) checkIfServerIsAvailable;
@end

#pragma mark - Implementation
#pragma mark Properties
@implementation SourceSyphon
@synthesize syClient;
@synthesize srcDescription;
@synthesize openGLContext;
@synthesize pixelFormat;
@synthesize delegate;
@synthesize waitingForServerObserver;
@synthesize validPropertyObserver;
@synthesize isValid;
 
#pragma mark Initialization

- (id) init
{
    self = [super init];
    if (self)
    {
        isValid = NO;
    }
    return self;
}

- (SourceSyphon *) initWithDescription:(NSDictionary *)description {
    
    self = [self init];
    if (self)
    {
        
        
        NSString *serverName = [description objectForKey:SyphonServerDescriptionNameKey];
        NSString *appName = [description objectForKey:SyphonServerDescriptionAppNameKey];
        
        if (!serverName || !appName)
        {
            self=nil;
            return nil;
        }
        
        srcDescription = [NSDictionary dictionaryWithObjectsAndKeys: 
                          serverName, SyphonServerDescriptionNameKey,
                          appName, SyphonServerDescriptionAppNameKey,
                          nil];
        
        
        
        NSDictionary *concreteDescr = [self checkIfServerIsAvailable];
        if (concreteDescr)
            [self setupSyphonInWithDescription: concreteDescr];
        else
            [self waitForServer];
    }
    return self;
}


-(void)dealloc
{
    if (syClient.isValid)
        [syClient stop];
    delegate=nil;
}

#pragma mark Private methods

- (NSDictionary *) checkIfServerIsAvailable
{
    NSString *serverName = [srcDescription objectForKey:SyphonServerDescriptionNameKey];
    NSString *appName = [srcDescription objectForKey:SyphonServerDescriptionAppNameKey];
    
    NSArray *matchingServers = [[SyphonServerDirectory sharedDirectory] serversMatchingName: serverName
                                                                                    appName: appName ];
    
    NSDictionary *concreteSyServer;
    BOOL result = matchingServers.count>0;
    if (result)
    {
        concreteSyServer = matchingServers.lastObject;
        return concreteSyServer;
    }
    
    return nil;
    
}

- (void) waitForServer
{
    waitingForServerObserver= [[SyphonServerDirectory sharedDirectory] addObserverForKeyPath:@"servers" task:^(id sender) {
        NSDictionary *concreteServerDescr= [self checkIfServerIsAvailable];
        if (concreteServerDescr)
        {        
            [self setupSyphonInWithDescription: concreteServerDescr];
            [[SyphonServerDirectory sharedDirectory] removeObserversWithIdentifier: waitingForServerObserver];
            
        }
    } ];
                               

}

- (void) setupSyphonInWithDescription: (NSDictionary *)syphonDescription
{
    // avverti il delegato
    if ([delegate respondsToSelector:@selector(syphonSource:didOpenSyphonClientAtTime:)])
        [delegate syphonSource:self didOpenSyphonClientAtTime: [NSDate date] ];

    fpsStart = [NSDate timeIntervalSinceReferenceDate];
    textureSourceStart = [NSDate timeIntervalSinceReferenceDate]; 
    fpsCount = 0;
    FPS = 0;
    
    syClient= [[SyphonClient alloc] initWithServerDescription: syphonDescription 
                                                      options: nil 
                                              newFrameHandler: ^(SyphonClient *client) {
        
        //@autoreleasepool 
        {
            // This gets called whenever the client receives a new frame.
            if (self.delegate)
            {
                // First we track our framerate...
                fpsCount++;
                float elapsed = [NSDate timeIntervalSinceReferenceDate] - fpsStart;
                if (elapsed > 1.0)
                {
                    FPS = ceilf(fpsCount / elapsed);
                    fpsStart = [NSDate timeIntervalSinceReferenceDate];
                    fpsCount = 0;
                }
                
                NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
                if ((self.delegate) && ([self.delegate respondsToSelector: @selector(syphonSource:didReceiveNewFrameAtTime:)]))
                    [self.delegate syphonSource: self 
                       didReceiveNewFrameAtTime: now-textureSourceStart ];
                
            };
        }
        
    }];
    
    [self willChangeValueForKey:@"isValid"];
    isValid = YES;
    [self didChangeValueForKey:@"isValid"];

    validPropertyObserver= [[SyphonServerDirectory sharedDirectory] addObserverForKeyPath:@"servers" 
                                                                                     task:^(id sender) {
                                                                                         
                                NSDictionary *concreteServerDescr= [self checkIfServerIsAvailable];
                                if (!concreteServerDescr)
                                {        
                                    [[SyphonServerDirectory sharedDirectory] removeObserversWithIdentifier:validPropertyObserver];
                                    [syClient stop];
                                    syClient = nil;
                                    
                                    [self waitForServer];

                                    if ([delegate respondsToSelector:@selector(syphonSource:didCloseSyphonClientAtTime:)])
                                        [delegate syphonSource:self didCloseSyphonClientAtTime:[NSDate timeIntervalSinceReferenceDate] -textureSourceStart];

                                    [self willChangeValueForKey:@"isValid"];
                                    isValid = NO;
                                    [self didChangeValueForKey:@"isValid"];

                                    
                                }
                            }];


    
}



#pragma mark TextureSource protocol imlpementation
- (GLuint) textureName 
{   return _texture; }

- (NSSize) textureSize
{ return NSMakeSize(frameWidth, frameHeight); }
@end
