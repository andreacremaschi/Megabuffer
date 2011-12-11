//
//  MBScrubberObject.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBScrubberObject.h"

#import "MBBufferObject.h"


@implementation MBScrubberObject
@synthesize delay;
@synthesize scrubMode;
@synthesize rate;
@synthesize syphonOut;
@synthesize buffer;





-(void)dealloc 
{
    buffer=nil;
    syphonOut    = nil;
}



#pragma mark - Methods

- (CIImage *)currentFrame
{
    return [buffer imageAtTime: 0];
}


@end
