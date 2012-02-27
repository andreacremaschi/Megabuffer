//
//  SyphonSourceViewController.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SyphonSourceViewController.h"
#import "SyphonSourceView.h"

@implementation SyphonSourceViewController

-(void)setServerDescription:(NSDictionary *)serverDescription
{
    self.representedObject = serverDescription;
}

-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    [self.view setNeedsDisplay: YES];
}
-(NSDictionary *)serverDescription
{
    return self.representedObject;
}

- (IBAction)resetSelectedServer:(id)sender {
    self.representedObject = nil;
}

- (void)loadView
{
    [super loadView];
    if ([self.view respondsToSelector:@selector(delegate)])
    {
        [(SyphonSourceView *)self.view setDelegate: self];

        
    }
}

@end
