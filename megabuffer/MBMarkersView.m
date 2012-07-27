//
//  MBMarkersView.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 09/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MBMarkersView.h"

@interface MBMarkersView ()
@property (strong, nonatomic) NSMutableDictionary *buttonsDict;
@end

@implementation MBMarkersView
@synthesize markersArray;
@synthesize buttonsDict;
@synthesize maxDelay;
@synthesize curTime;

#pragma mark - Initialization

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        buttonsDict = [NSMutableDictionary dictionary];
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    
 //   [self lockFocus];
    
    NSRect aRect = self.bounds;
    
    // calcola il quadrato complessivo della barra    
    NSBezierPath* thePath = [NSBezierPath bezierPath];    
    [thePath appendBezierPathWithRoundedRect:aRect xRadius:5 yRadius:5];
    
    // disegna il riempimento grigio chiaro
    [[NSColor grayColor] setFill];
    [thePath fill];
    
    // disegna il contorno grigio scuro
    [[NSColor blackColor] setStroke];
    [thePath stroke];
    
    // disegna la timeline
    double viewScalePix =  aRect.size.width / maxDelay ;
    double step=1;
    double majStep=5;
    double i = floor((curTime - maxDelay) / step) * step;
    double j = floor((curTime - maxDelay) / majStep) * majStep;
    if (j<i) j+=majStep;
    NSBezierPath *tickPath = [NSBezierPath bezierPath]; 
    NSBezierPath *majPath = [NSBezierPath bezierPath]; 
    double x;
    double startY = 2;
    double endY = self.frame.size.height-2;
    NSBezierPath *curPath;
    while (i<curTime)
    {

        x = (maxDelay-curTime+ i)*viewScalePix;
        if (i==j)
        {
            curPath = majPath;
            j+=majStep;
        }
        else
            curPath = tickPath;
            
        [curPath moveToPoint:NSMakePoint(x, startY)];
        [curPath lineToPoint:NSMakePoint(x, endY)];        

        
        
        i +=step;
    }
    [[NSColor darkGrayColor] setStroke];
    [tickPath setLineWidth: 0.5];
    [tickPath stroke];
    
    [[NSColor darkGrayColor] setStroke];
    [majPath setLineWidth: 3];
    [majPath stroke];
    
    // disegna i markers
    [[NSColor orangeColor] setFill];
    [[NSColor darkGrayColor] setStroke];
    for (NSString * markerKey in buttonsDict)
    {
//        NSButton *curButton = [buttonsDict objectForKey: markerKey];
        float markerTime = [markerKey doubleValue];
        
        double newButtonCenterX  = aRect.size.width - viewScalePix * (curTime-markerTime);

        
        float markerSize = 8.0;
        NSRect frame = NSMakeRect(newButtonCenterX - markerSize/2, aRect.origin.y + (aRect.size.height - markerSize) * 0.5, markerSize, markerSize);
        thePath = [NSBezierPath bezierPath];
        [thePath appendBezierPathWithRect: frame];//  RoundedRect:frame xRadius:2 yRadius:2];

        [thePath stroke];
        [thePath fill];

       //  NSLog(@"%@", NSStringFromRect(frame));
    }
    
//    [self unlockFocus];

}

- (void) updateButtons
{
    for (NSString * markerKey in buttonsDict)
    {
        NSButton *curButton = [buttonsDict objectForKey: markerKey];
        float markerTime = [markerKey doubleValue];

        double viewScalePix =  self.frame.size.width / maxDelay ;
        double newButtonCenterX  = self.frame.size.width - viewScalePix * (curTime-markerTime);
        if (newButtonCenterX < 0)
        {
            [curButton removeFromSuperview];
            
        }
            
        NSRect frame = curButton.frame;
        frame.origin.x = newButtonCenterX - frame.size.width / 2;
        curButton.frame = frame;
        curButton.hidden = YES;
       // NSLog(@"%@", NSStringFromRect(frame));
    }
}

-(void)setCurTime:(NSTimeInterval)time
{
    curTime = time;
    self.needsDisplay = YES;
 //   [self updateButtons]; //TODO: ottimizzare
}

- (void) setMarkersArray:(NSMutableArray *)array
{
    for (id marker in array)
        if (![[buttonsDict allKeys] containsObject: marker])
        {
            float buttonSize = 16;
            NSButton *newButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, (self.frame.size.height - buttonSize) / 2, buttonSize, buttonSize)];             
            [self addSubview: newButton];
            [buttonsDict setObject: newButton forKey: marker];
            [self updateButtons];
        }
    
    return;
}

@end
