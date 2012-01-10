//
//  MBMarkersView.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 09/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBMarkersView : NSControl

@property (strong, nonatomic) NSMutableArray *markersArray;
@property (nonatomic) NSTimeInterval curTime;
@property (nonatomic) NSTimeInterval maxDelay;


@end
