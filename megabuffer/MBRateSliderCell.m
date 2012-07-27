//
//  MBSliderCell.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 01/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MBRateSliderCell.h"

@interface MBRateSliderCell() 
@property (strong) NSImage *_knobOff;
@property (strong) NSImage *_knobOn;
@end

@implementation MBRateSliderCell
@synthesize _knobOff;
@synthesize _knobOn;

-(id)init {
    self = [super init];
    _knobOff = [NSImage imageNamed:@"Syphon Icon"];
    _knobOn = [NSImage imageNamed:@"Syphon Icon"];
    return self;
}


- (void)drawKnob:(NSRect)knobRect {
    
//    NSImage * knob = _knobOn;
    
    [[self controlView] lockFocus];

    float fraction = 0.7;
    
    float knobSize = knobRect.size.width*fraction;
    float offset = (knobRect.size.width - knobSize) / 2.0;
    NSRect ovalRect = NSMakeRect(knobRect.origin.x + offset, knobRect.origin.y+ offset, 
                                 knobSize, knobSize);
    
    
    NSBezierPath* thePath = [NSBezierPath bezierPath];    
    [[NSColor darkGrayColor] setFill];
    [thePath appendBezierPathWithOvalInRect: ovalRect];
    [thePath fill];
    
    [[self controlView] unlockFocus];
}

void DrawRoundedRect(NSRect rect, CGFloat x, CGFloat y)
{
    NSBezierPath* thePath = [NSBezierPath bezierPath];
    
    [thePath appendBezierPathWithRoundedRect:rect xRadius:x yRadius:y];
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
    [[self controlView] lockFocus];
    [[NSColor darkGrayColor] setFill];

    NSBezierPath* thePath = [NSBezierPath bezierPath];    
    [thePath appendBezierPathWithRoundedRect:aRect xRadius:5 yRadius:5];

    [[NSColor lightGrayColor] setFill];
    [thePath fill];
    
    [[NSColor blackColor] setStroke];
    [thePath stroke];


    [[self controlView] unlockFocus];
    
}
/*- (void)drawBarInside:(NSRect)rect flipped:(BOOL)flipped {
    rect.size.height = 8;
    
    NSRect knobrect = NSMakeRect(0,0, _knobOn.size.width, _knobOn.size.height);
    
    NSRect leftRect = rect;
    leftRect.origin.x=0;
    leftRect.origin.y=2;
    leftRect.size.width = knobrect.origin.x + (knobrect.size.width);
    [leftBarImage setSize:leftRect.size];
    [leftBarImage drawInRect:leftRect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction:1];
    
    NSRect rightRect = rect;
    rightRect.origin.x=0;
    rightRect.origin.y=2;
    rightRect.origin.x = knobrect.origin.x;
    [rightBarImage setSize:rightRect.size];
    [rightBarImage drawInRect:rightRect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction:1];
}*/

@end
