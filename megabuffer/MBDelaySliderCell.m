//
//  MBDelaySliderCell.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 07/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MBDelaySliderCell.h"

@implementation MBDelaySliderCell




- (void)drawKnob:(NSRect)knobRect {
    
    //    NSImage * knob = _knobOn;
    
    [[self controlView] lockFocus];
    
    float fraction = 0.9;
    
    NSSize knobSize =  NSMakeSize(3, knobRect.size.width*fraction);
    float offsetX = (knobRect.size.width - knobSize.width) / 2.0;
    float offsetY = (knobRect.size.height - knobSize.height) / 2.0;
    NSRect ovalRect = NSMakeRect(knobRect.origin.x + offsetX, knobRect.origin.y+ offsetY, 
                                 knobSize.width, knobSize.height);
    
    
    NSBezierPath* thePath = [NSBezierPath bezierPath];    
    [[NSColor darkGrayColor] setFill];
    [thePath appendBezierPathWithRect:ovalRect];
    [thePath fill];
    
    [[self controlView] unlockFocus];
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{

    [[self controlView] lockFocus];
    

    // calcola il quadrato complessivo della barra    
    NSBezierPath* thePath = [NSBezierPath bezierPath];    
    [thePath appendBezierPathWithRoundedRect:aRect xRadius:5 yRadius:5];

    // calcola il quadrato di riempimento per il valore dello slider  
    double handleSizePix = 6;
    NSRect insideRect = aRect;
    insideRect.origin.x+=handleSizePix;
    insideRect.size.width -= handleSizePix*2;
    NSBezierPath* valuePath = [NSBezierPath bezierPath];
    float valuePix = insideRect.size.width * (self.doubleValue / (self.maxValue - self.minValue));
    NSRect valueRect = NSMakeRect(insideRect.origin.x + valuePix, insideRect.origin.y, insideRect.size.width-valuePix, insideRect.size.height);
    [valuePath appendBezierPathWithRect:valueRect];

    
    // disegna il riempimento grigio chiaro
    [[NSColor lightGrayColor] setFill];
    [thePath fill];

    // disegna la barra colorata
    [[NSColor yellowColor] setFill];
    [valuePath fill];

    
    
    // disegna il contorno grigio scuro
    [[NSColor blackColor] setStroke];
    [thePath stroke];
    
    
    [[self controlView] unlockFocus];
    
}

@end
