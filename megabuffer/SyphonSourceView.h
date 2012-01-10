//
//  SyphonSourceView.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *serverDescriptionPBoardType;

@interface SyphonSourceView : NSView <NSDraggingDestination>

// properties
//@property (strong, nonatomic) NSDictionary *serverDescription; 
@property (unsafe_unretained, nonatomic) id delegate;
@end


@interface NSObject (SyphonSourceView_delegate)
@property (strong, nonatomic) NSDictionary *serverDescription;

@end