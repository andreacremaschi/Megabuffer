//
//  MBBufferController.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 20/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MBBufferController.h"
#import "BDocument.h"
#import "MBBufferObject.h"
#import "MBScrubberObject.h"

#import "NSObject+BlockObservation.h"
#import "MBOSCPropertyBindingController.h"
 
#import "ConciseKit.h"

#define MB_FPS 24.0 


@interface MBBufferController () {
    bool dropNext;
    NSRunLoop *_timerRunLoop;
    NSThread *_timerThread;

    bool _recording;
}

@property (unsafe_unretained) BDocument *  _document;

@property bool waitForFirstFrame;
@property NSTimeInterval lastWrittenIndex;
@property NSTimeInterval lastPushTime;
@property NSTimeInterval timeIndexStart;


- (void)timerFire:(NSTimer*)theTimer;
- (void) stop;

@end



@implementation MBBufferController

// Properties
@synthesize timer;
@synthesize fps;
@synthesize _document;
@synthesize recording;
@synthesize timeIndexStart, lastWrittenIndex;
@synthesize waitForFirstFrame;
@synthesize lastPushTime;

// Methods
#pragma mark - Initialization
- (id)init
{
    self = [super init];
    if (self)
    {
       
        // Kick off a new Thread
        [NSThread detachNewThreadSelector:@selector(createTimerRunLoop) 
                                 toTarget:self 
                               withObject:nil];
        
        dropNext=NO;
        fps=[NSNumber numberWithInt: MB_FPS];
                _recording = NO;
        lastWrittenIndex = 0;
        waitForFirstFrame = YES;
        
    }
    return self;
}

- (id) initWithDocument: (BDocument *)bufferDocument
{
    self = [self init];
    if (self)
    {
        _document = bufferDocument;
        [self setupOSCBindings];
    }
    return self;
}


-(void)dealloc
{
    _document=nil;
    
    [timer invalidate];
}

#pragma mark - Timer methods
- (void) createTimerRunLoop
{
    _timerRunLoop = [NSRunLoop currentRunLoop];
    _timerThread = [NSThread currentThread];
    timeIndexStart = [NSDate timeIntervalSinceReferenceDate];

    [self createTimer];
    
    while ([_timerRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);

}


- (void) createTimer{
    @autoreleasepool {
        
        dropNext=false;
        
        // Create a time for the thread
        timer = [NSTimer timerWithTimeInterval: 1.0/ self.fps.doubleValue
                                        target: self 
                                      selector: @selector(timerFire:)
                                      userInfo: nil 
                                       repeats: YES];
        
        // Add the timer to the run loop
        [_timerRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];


    }        
}

- (void)timerFire:(NSTimer*)theTimer
{
    
    
    if (dropNext) 
    {
        // NSLog(@"%@ drop a frame.", self);
        return;   
    }
    @synchronized(timer)
    {
        
        if ((!timer.isValid) )
            return;
        
        @autoreleasepool {
            dropNext=YES;
            [self _timerTick];
            dropNext=NO;
            
//            CVOpenGLTextureCacheFlush(_textureCache, 0);
            
        }
    }
}

#pragma mark - Accessors

- (void)setRecording:(bool)value
{
    recording = value;
    self.waitForFirstFrame = YES;
}

-(void)setFps:(NSNumber *)value
{
    [self stop];
    fps=[NSNumber numberWithDouble: fabs(value.doubleValue)];
    [self createTimer];
    
}

- (void) stop
{
    @synchronized (timer)
    {
        [timer invalidate];
        timer=nil;
    }
}

#pragma mark - Timer tick

- (void) _timerTick
{ 
    @autoreleasepool {
        
        

        if (self.recording)
        {           
            NSDictionary *metadataDict = nil;
            
            // calcola l'indice temporale del nuovo frame
            NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate] - timeIndexStart;
            
            // deltaTime è:
            NSTimeInterval deltaTime;
            if (!waitForFirstFrame)
                
                // il tempo trascorso dal push dell'ultimo frame se si era sempre in registrazione
                deltaTime = timestamp - self.lastPushTime;
            
            else
            {
                // se non si era in registrazione, uno step calcolato in base al framerate
                self.waitForFirstFrame = NO;
                deltaTime = 1.0 / [self.fps doubleValue];
                metadataDict = $dict($bool(YES), @"firstFrame");
            }
            NSTimeInterval indexTimestamp = self.lastWrittenIndex + deltaTime;
            
            // registra il nuovo frame nel buffer all'indice temporale corrente
            [_document.buffer pushNewFrameAtTimeIndex: indexTimestamp 
                                             metadata: metadataDict];
            self.lastWrittenIndex = indexTimestamp;
            self.lastPushTime = timestamp;
        }
        
        [_document.scrubber _timerTick];
    }
}


#pragma mark - OSC bindings
- (NSSet *)attributes
{
    // buffer osc messages
    NSSet *attributesSet = [NSSet setWithObjects: @"fps", @"bufferSize", @"addMarker", @"addMarkerWithLabel", 
                            @"syInServerName", @"syInApplicationName", nil];
    // scrubber osc messages
    attributesSet = [attributesSet setByAddingObjectsFromSet: 
                     [NSSet setWithObjects: @"scrubber/delay", @"scrubber/scrubMode", @"scrubber/rate", @"scrubber/gotoNextMarker", @"scrubber/gotoPrevMarker", @"scrubber/gotoMarkerWithLabel", @"scrubber/autoScrubToDelay", @"scrubber/autoScrubDuration", @"scrubber/gotoDelay", nil]];
    return attributesSet;
}

- (void) setupOSCBindings
{       
    // bind the buffer controller
    NSSet *bindingNames = [self attributes];
    for (NSString *newBinding in bindingNames)
    {
        
        NSString *bindingPath =  [NSString stringWithFormat: @"/%@", newBinding];
        [[MBOSCPropertyBindingController sharedController]  bindOSCMessagesWithAddress: bindingPath
                                                                              toObject: self 
                                                                           withKeyPath: newBinding
                                                                               options: nil];
    }
}


#pragma mark - Getter/setter for buffer and scrubber properties
- (void) setValue: (id)value 
       forKey:(NSString *)keyPath
{
    NSString *selectorName = @"";
    if ([keyPath characterAtIndex: 0] == '/')
    {
        // osc message
        if (keyPath.length>10 && [[keyPath substringWithRange:NSMakeRange(0, 10)] isEqualToString:@"/scrubber/"])
        {          
            NSString *newKeyPath = [keyPath substringWithRange:NSMakeRange(10, keyPath.length-10)];
            // scrubber related message
            if (newKeyPath.length>4 && [[newKeyPath substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"goto"])
            {          
                //goto command
                selectorName = $str(@"%@:", newKeyPath);
            }
            else {
                //property setter
                NSString *newKeyPath = [keyPath substringWithRange:NSMakeRange(10, keyPath.length-10)];
                newKeyPath = [[newKeyPath substringToIndex:1].capitalizedString stringByAppendingString: [newKeyPath substringWithRange:NSMakeRange(1, newKeyPath.length-1)]];
                
                selectorName = [NSString stringWithFormat:@"set%@:", newKeyPath];                
                
            }
            SEL selector = NSSelectorFromString(selectorName );
            if ([_document.scrubber respondsToSelector: selector])
                [_document.scrubber performSelector:selector
                                           onThread:_timerThread
                                         withObject:value
                                      waitUntilDone:NO];

        } else {
            NSString *newKeyPath = [keyPath substringWithRange:NSMakeRange(1, keyPath.length-1)];
            newKeyPath = [[newKeyPath substringToIndex:1].capitalizedString stringByAppendingString: [newKeyPath substringWithRange:NSMakeRange(1, newKeyPath.length-1)]];
            NSString *setterSelectorName = [NSString stringWithFormat:@"set%@:", newKeyPath];
            
            SEL setter = NSSelectorFromString(setterSelectorName);
            if ([_document.buffer respondsToSelector: setter])
                [_document.buffer performSelector:setter
                                           onThread:_timerThread
                                         withObject:value
                                      waitUntilDone:NO];
        }
        
    }
    else {
        [super setValue:value
                 forKey: keyPath];
    }
        
}

- (id)valueForKeyPath:(NSString *)keyPath   
{
    if ([keyPath characterAtIndex: 0] == '/')
    {
        if (keyPath.length>10 && [[keyPath substringWithRange:NSMakeRange(0, 10)] isEqualToString:@"/scrubber/"])
        {
            NSString *newKeyPath = [keyPath substringWithRange:NSMakeRange(10, keyPath.length-10)];
/*            NSString *getterSelectorName = newKeyPath; //[NSString stringWithFormat:@"%@", newKeyPath];
            
            SEL getter = NSSelectorFromString(getterSelectorName );
            if ([_document.scrubber respondsToSelector: getter])
            {
                return [_document.scrubber performSelector: getter];
            }*/
            return [_document.scrubber valueForKeyPath: newKeyPath];
            } else {
                NSString *newKeyPath = [keyPath substringWithRange:NSMakeRange(1, keyPath.length-1)];
                return [_document.buffer valueForKeyPath: newKeyPath];
        }
        
    }
    else {
        return [super valueForKeyPath:keyPath];
    }
    
}

    
+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    static NSDictionary * _dict = nil;
    if (_dict == nil)
    {
        _dict = $dict(
                      $set(@"_document.buffer.bufferSize"), @"/bufferSize",
                      $set(@"_document.buffer.syInApplicationName"), @"/syInApplicationName",
                      $set(@"_document.buffer.syInServerName"), @"/syInServerName",
                      $set(@"_document.scrubber.autoScrubDuration"), @"/scrubber/autoScrubDuration",
                      $set(@"_document.scrubber.autoScrubDelay"), @"/scrubber/autoScrubDelay",
                      $set(@"_document.scrubber.delay"), @"/scrubber/delay",
                      $set(@"_document.scrubber.rate"), @"/scrubber/rate",
                      $set(@"_document.scrubber.scrubMode"), @"/scrubber/scrubMode"
        );
    }
    NSSet *set = [_dict objectForKey:key];
    return set ? set : [super keyPathsForValuesAffectingValueForKey:key];
    
}

@end
