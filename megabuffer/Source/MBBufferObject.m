//
//  MBBufferObject.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 08/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBBufferObject.h"
#import "SourceSyphon.h"
#import "NSMutableStack.h"

#import <Syphon/Syphon.h>
#import <OpenGL/CGLMacro.h>

#pragma mark - Extension @interface
@interface MBBufferObject ()
{
    CVOpenGLBufferPoolRef _bufferPool;    
    NSSize _frameSize;
    SyphonImage *_image;
    CVOpenGLTextureRef _texture;
    CVOpenGLTextureCacheRef _textureCache;
    NSTimeInterval bufferStart;
    NSTimeInterval lastReceivedFrameTimestamp;
    NSTimeInterval lastPushFrameTimestamp;
    NSTimeInterval lastPushFrameIndexTimestamp;
    bool waitForFirstFrame;
    bool addMarkerToNextFrame;
    bool _recording;
}
@property uint _bufferSize;
@end


#pragma mark - @implementation
@implementation MBBufferObject
@synthesize syphonIn;

//@synthesize _recording;
@synthesize curTime;
@synthesize curIndexTime;

@synthesize markersArray;

@synthesize syInServerName;
@synthesize syInApplicationName;
@synthesize _bufferSize;

@synthesize frameStack;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.name = @"buffer";
        markersArray = [NSMutableArray array];
        _bufferSize = 250; //10 secondi a 25 fps
        _frameSize = NSMakeSize(0,0);
        _texture=nil;
        _recording = true;
        frameStack = [[NSMutableStack alloc] init];
        bufferStart = [NSDate timeIntervalSinceReferenceDate];
        lastPushFrameIndexTimestamp = 0;
        waitForFirstFrame = true;
        addMarkerToNextFrame = false;
        
        NSError *error;
        if (! [self initOpenGLContextWithSharedContext: nil error: &error]) 
        {
            NSLog(@"Error: couldn't init Opengl shared context.\n%@", error);
            self = nil;
            return nil;
        }
    }
    return self;
}


-(void)dealloc 
{
    syphonIn.delegate     = nil;
}

#pragma mark - Accessors

-(void)set_recording:(_Bool)newVal    
{
    if (newVal!=_recording) 
        waitForFirstFrame= newVal == YES;
    _recording=newVal;
}
- (_Bool)_recording
{
    return _recording;
}

+ (NSSet *)keyPathsForValuesAffectingSyInApplicationName
{
    return [NSSet setWithObject:@"serverDescription"];
}

+ (NSSet *)keyPathsForValuesAffectingSyInServerName
{
    return [NSSet setWithObject:@"serverDescription"];
}

-(void)setServerDescription:(NSDictionary *)serverDescription   
{
    // ferma il vecchio syphon client
    if (syphonIn)
    {
        [syphonIn.syClient stop];
        syphonIn = nil;
    }
    
    // se la descrizione è valida, crea un nuovo syphon client
    if ([[serverDescription allKeys] containsObject: SyphonServerDescriptionNameKey] &&
        [[serverDescription allKeys] containsObject: SyphonServerDescriptionAppNameKey])
    {
        [self willChangeValueForKey:@"serverDescription"];
        syInServerName = [serverDescription valueForKey: SyphonServerDescriptionNameKey];
        syInApplicationName = [serverDescription valueForKey: SyphonServerDescriptionAppNameKey];        
        syphonIn = [[SourceSyphon alloc] initWithDescription: serverDescription];
        syphonIn.delegate = self;
        [self didChangeValueForKey:@"serverDescription"];
    }
}

-(NSDictionary *)serverDescription
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.syInServerName, SyphonServerDescriptionNameKey,
            self.syInApplicationName, SyphonServerDescriptionAppNameKey, 
            nil];
}

- (void)setSyInApplicationName:(NSString *)newVal
{
    if ([syInServerName isEqualToString: newVal]) return;    
    syInApplicationName = [newVal copy];
    [self setServerDescription: [NSDictionary dictionaryWithObjectsAndKeys:
                                 syInServerName, SyphonServerDescriptionNameKey,
                                 syInApplicationName, SyphonServerDescriptionAppNameKey,
                                 nil]];
}

-(void)setSyInServerName:(NSString *)newVal
{
    if ([syInServerName isEqualToString: newVal]) return;
    syInServerName = [newVal copy];
    [self setServerDescription: [NSDictionary dictionaryWithObjectsAndKeys:
                                 syInServerName, SyphonServerDescriptionNameKey,
                                 syInApplicationName, SyphonServerDescriptionAppNameKey,
                                nil]];
}

-(NSTimeInterval)maxDelay
{
    return (NSTimeInterval)_bufferSize / [self.fps doubleValue];
}

#pragma mark - Attributes
- (NSSet *)attributes
{
    return [[super attributes] setByAddingObjectsFromSet:
            [NSSet setWithObjects: @"bufferSize", @"recording", @"addMarker", @"addMarkerWithLabel",  nil]];
}

-(void)setBufferSize:(NSNumber *)bufferSize
{   _bufferSize = [bufferSize intValue];    }

- (NSNumber *)bufferSize
{   return [NSNumber numberWithInt: _bufferSize]; }

- (void) setRecording: (NSNumber *)recording
{   self._recording = recording.boolValue;}

- (NSNumber *) recording
{   return [NSNumber numberWithBool: _recording];}

-(void)setAddMarker:(id)options
{   addMarkerToNextFrame=YES;   }

-(void)setAddMarkerWithLabel:(id)options
{   addMarkerToNextFrame=YES;
    // TODO: implementare
}


#pragma mark maxDelay

+ (NSSet *)keyPathsForValuesAffectingMaxDelay
{
    return [NSSet setWithObjects: @"bufferSize", @"fps", nil];
}

-(void)setMaxDelay:(NSTimeInterval)maxDelay
{
    [self set_bufferSize: maxDelay * [self.fps doubleValue]];
}

- (CIImage *)ciImageAtTime: (NSTimeInterval) time
{
    if (frameStack.count>0)
    {
        CVPixelBufferRef oldBuffer = [[[frameStack objectAtIndex: 0] valueForKey: @"image"] pointerValue];

        return [CIImage imageWithCVImageBuffer:oldBuffer];
    }
    else return [CIImage emptyImage];
}

#pragma mark - Graphical stuff init


- (bool)initCVOpenGLBufferPoolWithSize: (NSSize) size
								 error: (NSError **)error {
    
	CVReturn						theError;

    // destroy old bufferpool
    if(_bufferPool)
        CVOpenGLBufferPoolRelease(_bufferPool);
    
	//Create buffer pool
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    //	[attributes setObject:[NSNumber numberWithUnsignedInt:15] forKey:(NSString*)kCVOpenGLBufferPoolMinimumBufferCountKey];
    //	[attributes setObject:[NSNumber numberWithUnsignedInt:0.3] forKey:(NSString*)kCVOpenGLBufferPoolMaximumBufferAgeKey];
	[attributes setValue:[NSNumber numberWithInt:size.width] forKey:(NSString*)kCVOpenGLBufferWidth];
	[attributes setValue:[NSNumber numberWithInt:size.height] forKey:(NSString*)kCVOpenGLBufferHeight];
	
    CFDictionaryRef cfDict = CFBridgingRetain(attributes);
	theError = CVOpenGLBufferPoolCreate(kCFAllocatorDefault, NULL, cfDict, &_bufferPool);
    CFBridgingRelease(cfDict);
    
	if(theError) {
		NSLog(@"CVPixelBufferPoolCreate() failed with error %i", theError);
		return false;
	}
	//CVOpenGLBufferPoolRetain(_bufferPool);
        
	return (theError == kCVReturnSuccess);
	
}


#pragma mark - TextureSourceDelegate implementation

-(void)syphonSource:(SourceSyphon *)sourceSyphon 
didReceiveNewFrameAtTime:(NSTimeInterval)time
{
    lastReceivedFrameTimestamp = [NSDate timeIntervalSinceReferenceDate] - bufferStart;
}

-(void) _timerTick
{
    if (!self.openGLContext) return;
    if (!self._recording) return; // non in record mode: ignora il nuovo frame
    
    SyphonClient *syClient = syphonIn.syClient;
    

    // controlla se il client syphon è valido
    if (!syClient || !syClient.isValid)
    {
        // non lo è: aggiunge un frame nero e passa oltre
        return;
    }
    
    
    if (lastPushFrameTimestamp > lastReceivedFrameTimestamp)
    {
        //  non è ancora arrivato un nuovo frame dall'ultimo push fatto.
        //  TODO: replica l'ultimo frame aggiunto
        //NSLog(@"ignoro");
        return;
    }
    
    NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate] - bufferStart;
    NSTimeInterval deltaTime;
    if (!waitForFirstFrame)
        deltaTime = timestamp - lastPushFrameTimestamp;
    else
        deltaTime = 1.0 / [self.fps doubleValue];
    NSTimeInterval indexTimestamp = lastPushFrameIndexTimestamp + deltaTime;
    
    waitForFirstFrame = false;
    
    [self lockTexture];
    
    SyphonImage *image = [syClient newFrameImageForContext: self.openGLContext.CGLContextObj];
	CGLContextObj cgl_ctx = self.openGLContext.CGLContextObj;
    
    
    if (!image)
    {
        // TODO: replica l'ultimo frame
        [self unlockTexture];
        return;
    }
    
    
	GLuint texture = [image textureName];
	NSSize imageSize = [image textureSize];
	
	BOOL changed = NO;
	if ((_frameSize.width != imageSize.width) || 
		(_frameSize.height != imageSize.height))
	{
		changed = YES;
		_frameSize.width = imageSize.width;
		_frameSize.height = imageSize.height;
		[self initCVOpenGLBufferPoolWithSize: imageSize error: nil];
	}
	
	if (changed)
	{		
		glViewport(0, 0, imageSize.width, imageSize.height);
		
		glMatrixMode(GL_MODELVIEW);    // select the modelview matrix
		glLoadIdentity();              // reset it
		
		glMatrixMode(GL_PROJECTION);   // select the projection matrix
		glLoadIdentity();              // reset it
		
		glOrtho(0, 0, imageSize.width, imageSize.height, -1.0, 1.0);// define a 2-D orthographic projection matrix
	}
	
    //Get pixel buffer from pool
    CVPixelBufferRef pixelBuffer;
    CVReturn theError = CVOpenGLBufferPoolCreateOpenGLBuffer (kCFAllocatorDefault, _bufferPool, &pixelBuffer);
    if(theError) {
        NSLog(@"CVOpenGLBufferPoolCreateOpenGLBuffer() failed with error %i", theError);
        [self unlockTexture];
        return;
    }	
    
    theError = CVOpenGLBufferAttach(pixelBuffer, 
                                    [self.openGLContext CGLContextObj], 
                                    0, 0, 
                                    [self.openGLContext currentVirtualScreen]);
    if (theError)	{
        NSLog(@"CVOpenGLBufferAttach() failed with error %i", theError);
        [self unlockTexture];
        return;
    }
    
	//Use 'texture' to get texture target/id, texture bind, render to quad etc.. 
	GLenum target = GL_TEXTURE_RECTANGLE_ARB;
	GLint name = texture;		
	{
		glEnable(target);
		glBindTexture(target, name);
        
        //glClearColor(1.0,0.0,0.0,1.0); 
        //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
		glBegin(GL_QUADS);
		{
			glTexCoord2f( imageSize.width, 0.0f );				glVertex2f(  1.0f, -1.0f );
			glTexCoord2f( 0.0f, 0.0f );							glVertex2f( -1.0f, -1.0f );
			glTexCoord2f( 0.0f, imageSize.height );				glVertex2f( -1.0f, 1.0f );
			glTexCoord2f( imageSize.width, imageSize.height );	glVertex2f(  1.0f, 1.0f );
		}
		glEnd();
        
		glFlush();
		glDisable(target);
		
        
        
        // è arrivato un nuovo frame? siamo in record mode? bisogna farne una copia e conservarla!         
        //        CIImage *ciImage = [CIImage imageWithCVImageBuffer: pixelBuffer];
        NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSValue valueWithPointer: pixelBuffer], @"image",
                                 [NSNumber numberWithDouble: indexTimestamp], @"timeIndex",
                                 [NSNumber numberWithDouble: timestamp], @"timeStamp",
                                 // todo: aggiungere un riferimento a un marker, da utilizzare quando il frame viene droppato
                                 nil];
       // NSLog (@"%@", newDict);
        
        if (addMarkerToNextFrame)
        {
            
           // NSDictionary *marker = [NSDictionary dictionaryWithObject: newDict forKey: [NSNumber numberWithDouble: indexTimestamp]];
            [self willChangeValueForKey:@"markersArray"];
            [markersArray addObject: [NSNumber numberWithDouble: indexTimestamp]];
            addMarkerToNextFrame = false;
            [self didChangeValueForKey:@"markersArray"];
        }
        NSDictionary *oldDict = [frameStack push: newDict];
        if (oldDict)
        {
            CVPixelBufferRef oldBuffer = [[oldDict valueForKey: @"image"] pointerValue];
            CVOpenGLBufferRelease(oldBuffer);
        }
        
        lastPushFrameIndexTimestamp = indexTimestamp;
        lastPushFrameTimestamp = timestamp;
        // Create the duplicate texture
      
        CVOpenGLTextureRef textureOut= [self createNewTextureFromBuffer: pixelBuffer];
        [self setCurrentTexture: textureOut];
        [self setCurrentFrameTimeStamp: indexTimestamp];
        CVOpenGLTextureRelease(textureOut);

        
	}
	
    [self unlockTexture];
    
    self.curIndexTime = lastPushFrameIndexTimestamp;
    self.curTime = timestamp;
    
    return;

}

#pragma mark - Frame stack management

- (NSTimeInterval) firstFrameInBufferTimeStamp
{
    if (frameStack.count==0) return -1;
    return [[[frameStack objectAtIndex:0] valueForKey:@"timeIndex"] doubleValue];
}

- (NSTimeInterval) lastFrameInBufferTimeStamp
{
    if (frameStack.count==0) return -1;
    return [[[frameStack lastObject] valueForKey:@"timeIndex"] doubleValue];
}

- (NSDictionary *)imageDictForDelay: (NSTimeInterval)delay
{
    NSTimeInterval preferredTimeStamp = delay + [self firstFrameInBufferTimeStamp];    
    int ceilPosition = ceil(delay * [self.fps doubleValue]); 
    int floorPosition = floor(delay * [self.fps doubleValue]);
    
    NSDictionary *imageDict1, *imageDict2;
    @synchronized(frameStack)
    {
        imageDict1 = frameStack.count > ceilPosition ? [frameStack objectAtIndex: ceilPosition] : nil;
        imageDict2 = frameStack.count > floorPosition ? [frameStack objectAtIndex: floorPosition] : nil;
    }
    NSTimeInterval time1 = [[imageDict1 valueForKey: @"timeIndex"] doubleValue];
    NSTimeInterval time2 = [[imageDict2 valueForKey: @"timeIndex"] doubleValue];
    
    return fabs(time2-preferredTimeStamp) < fabs(time1 - preferredTimeStamp) ? imageDict1 : imageDict2;
    
//    if (stackPosition>=buffer.frameStack.count) scrubPosition=buffer.frameStack.count-1;
    
    
}

#pragma mark - Markers
-(void) addMarkerToNextFrame
{
    addMarkerToNextFrame = YES;
}

- (NSTimeInterval) markerPrecedingPosition: (NSTimeInterval) indexTimeStamp
{
    NSTimeInterval curMarker = 0;
    NSTimeInterval prevMarker = 0;
    int i = 0;
    while ((indexTimeStamp> curMarker) && (markersArray.count> i)) {
        prevMarker=curMarker;
        curMarker = [[markersArray objectAtIndex: i]doubleValue];
        i++;
    }
    return curMarker<indexTimeStamp? curMarker : prevMarker;
}

- (NSTimeInterval) markerFollowingPosition: (NSTimeInterval) indexTimeStamp
{
    NSTimeInterval curMarker = [[markersArray objectAtIndex:markersArray.count-1] doubleValue];
    NSTimeInterval prevMarker = curMarker;
    int i = (int)markersArray.count-1;
    while ((indexTimeStamp< curMarker) && (i>=0)) {
        prevMarker=curMarker;
        curMarker = [[markersArray objectAtIndex: i] doubleValue];
        i--;
    }
    return curMarker>indexTimeStamp? curMarker : prevMarker;    
}

#pragma mark -Serialization
- (NSDictionary *)dictionaryRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.name ? self.name : @"", @"name",
            self.bufferSize , @"bufferSize",
            self.recording, @"recording",
            self.fps, @"fps",
            self.syphonIn.srcDescription, @"syphonSource",
            nil];
}

- (BOOL) setupWithDictionary: (NSDictionary *)dict
{
    self.name = [dict objectForKey:@"name"];
    self.bufferSize = [dict objectForKey:@"bufferSize"] ;
    self.fps = [dict objectForKey:@"fps"] ;
    self.recording = [dict objectForKey:@"recording"] ;
    [self setServerDescription: [dict objectForKey:@"syphonSource"]];
    return YES;
}

@end
