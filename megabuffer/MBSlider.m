//
//  MBSlider.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 01/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MBSlider.h"
#import "MBRateSliderCell.h"

@implementation MBSlider
- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    MBRateSliderCell * aCell = [[MBRateSliderCell alloc] init] ;
    [aCell setControlSize: NSSmallControlSize];
    aCell.maxValue = [self.cell maxValue];
    aCell.minValue = [self.cell minValue];
    
    [self setCell: aCell];
}

//invalidate everything!
-(void)setNeedsDisplayInRect:(NSRect)invalidRect{
    [super setNeedsDisplayInRect:[self bounds]];
}


@end
