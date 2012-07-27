//
//  MBOSCPropertyBindingController.h
//  megabuffer
//
//  Created by Andrea Cremaschi on 18/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VVOSC/VVOSC.h>

@interface MBOSCPropertyBindingController : NSObject

+ (MBOSCPropertyBindingController *)sharedController;

- (void)bindOSCMessagesWithAddress: (NSString *)binding 
                          toObject: (id)observable 
                       withKeyPath: (NSString *)keyPath 
                           options: (NSDictionary *)options;
- (void)unbindOSCAddress:(NSString *)address;

@property (unsafe_unretained, readonly, nonatomic) NSDictionary    *bindings;

@end
