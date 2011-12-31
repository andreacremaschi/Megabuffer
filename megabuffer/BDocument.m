//
//  BDocument.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 17/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BDocument.h"
#import "MBWindowController.h"

#import "MBBufferObject.h"
#import "MBScrubberObject.h"

#import "MBOSCPropertyBindingController.h"

#import "NSObject+BlockObservation.h"

@implementation BDocument
@synthesize buffer;
@synthesize scrubber;

- (id)init
{
    self = [super init];
    if (self) {
        buffer = [[MBBufferObject alloc] init];
        scrubber = [[MBScrubberObject alloc] init];
        scrubber.buffer = buffer;
        
        __unsafe_unretained BDocument *selfCopy= self;
        [buffer addObserverForKeyPath: @"name" task:^(id obj, NSDictionary *change) {

            // bind the buffer
            
            NSSet *bindingNames = [selfCopy.buffer attributes];
            for (NSString *newBinding in bindingNames)
            {
                
                NSString *bindingPath =  [NSString stringWithFormat: @"/%@/%@", [change valueForKey: NSKeyValueChangeOldKey], newBinding];
                [[MBOSCPropertyBindingController sharedController] unbindOSCAddress: bindingPath ];
                
                bindingPath =  [NSString stringWithFormat: @"/%@/%@", selfCopy.buffer.name, newBinding];
                [[MBOSCPropertyBindingController sharedController]  bindOSCMessagesWithAddress: bindingPath
                                                                                      toObject: selfCopy.buffer 
                                                                                   withKeyPath: @"recording" 
                                                                                       options: nil];
            }
            
            // bind the scrubber
            bindingNames = [selfCopy.scrubber attributes];
            
            for (NSString *newBinding in bindingNames)
            {
                if (selfCopy.scrubber.name)
                {
                     NSString *bindingPath =  [NSString stringWithFormat: @"/%@/%@/%@", [change valueForKey: NSKeyValueChangeOldKey], selfCopy.scrubber.name, newBinding ];
                    [[MBOSCPropertyBindingController sharedController] unbindOSCAddress:bindingPath ];
                    
                    bindingPath =  [NSString stringWithFormat: @"/%@/%@/%@", selfCopy.buffer.name, selfCopy.scrubber.name, newBinding ];
                    [[MBOSCPropertyBindingController sharedController]  bindOSCMessagesWithAddress: bindingPath 
                                                                                          toObject: selfCopy.scrubber 
                                                                                       withKeyPath: newBinding
                                                                                           options: nil];
                }
                
                __unsafe_unretained BDocument *selfCopy2= selfCopy;
                [selfCopy.scrubber addObserverForKeyPath:@"name" task:^(id obj, NSDictionary *change) {
                    
                    NSString *bindingPath2 =  [NSString stringWithFormat: @"/%@/%@/%@", selfCopy2.buffer.name, [change valueForKey: NSKeyValueChangeOldKey], newBinding ];
                    [[MBOSCPropertyBindingController sharedController] unbindOSCAddress: bindingPath2 ];
                    
                    bindingPath2 =  [NSString stringWithFormat: @"/%@/%@/%@", selfCopy2.buffer.name, selfCopy2.scrubber.name, newBinding ];
                    [[MBOSCPropertyBindingController sharedController]  bindOSCMessagesWithAddress: bindingPath2
                                                                                          toObject: selfCopy2.scrubber 
                                                                                       withKeyPath: newBinding
                                                                                           options: nil];
                    
                }];
                
            }
            
            
        }];
        

    
        
    }
    return self;
}

-(void)dealloc
{
    [scrubber stop];
}

-(void)awakeFromNib
{

    

}

#pragma mark - Serialization

- (NSDictionary *)dictionaryRepresentation
{
    NSDictionary *dict= [NSDictionary dictionaryWithObjectsAndKeys:
            buffer.dictionaryRepresentation, @"buffer",
            scrubber.dictionaryRepresentation, @"scrubber",
            nil];
    
    return dict;
    
}

- (BOOL) setupWithDictionary: (NSDictionary *)docDict
{
    NSDictionary *bufferDict = [docDict objectForKey:@"buffer"];
    NSDictionary *scrubberDict = [docDict objectForKey:@"scrubber"];
    
    if( ![bufferDict isKindOfClass:[NSDictionary class]] || ![scrubberDict isKindOfClass:[NSDictionary class]]) return NO;
    
    if (![self.buffer setupWithDictionary: bufferDict ]) return NO;
    if (![self.scrubber setupWithDictionary: scrubberDict ]) return NO;
    
    return YES;

}

#pragma mark - NSDocument overrides

- (void)makeWindowControllers
{
    MBWindowController *windowController = [[MBWindowController alloc] init];
    [self addWindowController: windowController];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    /*
     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    */

    NSString *error;
    NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList: [self dictionaryRepresentation]
                                                                 format: NSPropertyListXMLFormat_v1_0 
                                                       errorDescription: &error];
    if (!xmlData)
    {NSLog (@"%@", error);}
    
    
    return xmlData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    /*
    Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    */
    /*NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;*/
    
    NSDictionary *dict = [NSPropertyListSerialization propertyListWithData: data 
                                                                   options: NSPropertyListImmutable
                                                                    format: NULL
                                                                     error: outError];
    if (!dict)
    {  
        NSLog(@"%@", *outError);
        return NO;
    }

    return [self setupWithDictionary: dict];
}


#pragma mark -


@end
