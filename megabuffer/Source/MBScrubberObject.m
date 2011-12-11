//
//  MBScrubberObject.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBScrubberObject.h"

@implementation MBScrubberObject
@synthesize delay;
@synthesize scrubMode;
@synthesize rate;
@synthesize syphonOut;





-(void)dealloc 
{
    syphonOut    = nil;
}

@end
