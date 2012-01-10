//
//  SyphonSourceView.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SyphonSourceView.h"


#pragma mark - Symbols
NSString *serverDescriptionPBoardType = @"serverDescriptionPBoardType";

#pragma mark - Implementation

@implementation SyphonSourceView 
//@synthesize serverDescription;
@synthesize delegate;

#pragma mark - Initialization

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self registerForDraggedTypes:[NSArray arrayWithObjects:serverDescriptionPBoardType, nil]];
    }
    
    return self;
}

-(void)dealloc
{
 [self unregisterDraggedTypes];
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    if ([self.delegate respondsToSelector:@selector(serverDescription)])
    {
        NSDictionary * serverDescription= [self.delegate serverDescription];
        
            NSBezierPath *thePath = [NSBezierPath bezierPath];
            [thePath appendBezierPathWithRoundedRect: NSInsetRect(self.bounds, 15, 5)
                                             xRadius: 8 yRadius:8];
        if (!serverDescription)
        {

            [thePath setLineWidth: 2];
            CGFloat lineDash[2];
            lineDash[0] = 10.0;
            lineDash[1] = 10.0;
            [thePath setLineDash:lineDash count:2 phase: 0];
            [[NSColor lightGrayColor] setStroke];
            [thePath stroke];
//            self.layer.opacity=1.0;
        }
        else
        {
            /*[[NSColor lightGrayColor] setFill];
            self.layer.opacity=0.8;
            [thePath fill];*/
            
        }
    }
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) 
        == NSDragOperationGeneric)
    {

        return NSDragOperationLink;
    }
    else
    {
        return NSDragOperationNone;
    }
}


- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:serverDescriptionPBoardType] ) {
        // Only a copy operation allowed so just copy the data
        id serverDescr = [NSUnarchiver unarchiveObjectWithData: [pboard dataForType: serverDescriptionPBoardType]];
        if ([serverDescr isKindOfClass:[NSDictionary class]])
        {
            if ([self.delegate respondsToSelector:@selector(serverDescription)])                
            {
                [self.delegate setServerDescription: serverDescr];
                self.needsDisplay=YES;
                return YES;
            }
        }
        
    }
    return NO;
    
}


@end
