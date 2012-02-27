//
//  MBOSCPropertyBindingController.m
//  megabuffer
//
//  Created by Andrea Cremaschi on 18/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBOSCPropertyBindingController.h"


#pragma mark - Extension
@interface MBOSCPropertyBindingController()
@property (strong, nonatomic) OSCManager    *manager;
@property (strong, nonatomic) OSCInPort		*inPort;
@property (strong, nonatomic) OSCOutPort	*manualOutPort;	//	this is the port that will actually be sending the data
@property (strong, nonatomic) NSMutableDictionary    *_bindings;
@property (strong, nonatomic) NSMutableDictionary    *_lastValues;

@end


#pragma mark - Implementation
@implementation MBOSCPropertyBindingController
@synthesize manager;
@synthesize inPort;
@synthesize manualOutPort;
@synthesize _bindings;
@synthesize _lastValues;


#pragma mark - Singleton

+ (MBOSCPropertyBindingController *)sharedController
{
    static MBOSCPropertyBindingController *_sharedController;
    if (!_sharedController)
        _sharedController = [[MBOSCPropertyBindingController alloc] init];
    return _sharedController;
    
}

#pragma mark - Initialization


- (id)init
{
    self = [super init];
    if (self)
    {
        manager = [[OSCManager alloc] initWithInPortClass: [OSCInPort class] outPortClass:nil];
        
        //	by default, the osc manager's delegate will be told when osc messages are received
        [manager setDelegate:self];
        _bindings=[NSMutableDictionary dictionary];
        _lastValues=[NSMutableDictionary dictionary];

        //inPort = [manager createNewInput];
        inPort = [manager createNewInputForPort: 5000 withLabel:@"megabuffer"];
        
        //	register to receive notifications that the list of osc outputs has changed
    /*    [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(_oscOutputsChangedNotification:) 
                                                     name:OSCOutPortsChangedNotification 
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(_oscOutputsChangedNotification:) 
                                                     name:OSCInPortsChangedNotification 
                                                   object:nil];*/
        
        
    }
    return self;
}


- (void)dealloc
{
    _lastValues=nil;
    _bindings=nil;
    inPort=nil;
    manager=nil;
}

#pragma mark - _bindings

- (void)bindOSCMessagesWithAddress: (NSString *)binding 
                          toObject: (id)observable 
                       withKeyPath: (NSString *)keyPath 
                           options: (NSDictionary *)options
{
    // NSLog(@"adding key: %@", binding);
    
    NSMapTable *bindingMap = [NSMapTable mapTableWithStrongToStrongObjects];
    [bindingMap setObject: observable forKey: @"object"];
    [bindingMap setObject: keyPath forKey: @"keyPath"];    
    
    // TODO: controllare se l'oggetto risponde a quel keypath e fare qualcosa nel caso
    
    [self willChangeValueForKey:@"bindings"];
    [_bindings setObject: bindingMap
                 forKey: binding];
    [_lastValues setObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], @"value",
                             [NSNull null], @"timestamp",
                             nil]
                    forKey: binding];
    [self didChangeValueForKey:@"bindings"];    
}

- (void)unbindOSCAddress:(NSString *)address
{
    // NSLog(@"removing key: %@", address);
    [self willChangeValueForKey:@"bindings"];    
    [_lastValues removeObjectForKey: address];
    [_bindings removeObjectForKey: address];
    [self didChangeValueForKey:@"bindings"];    

}


+ (NSSet *)keyPathsForValuesAffectingBindings
{
    return [NSSet setWithObject: @"_lastValues"];
}

-(NSDictionary *)bindings
{
    return _lastValues;
}

#pragma mark - Observing callbacks

- (void) _oscOutputsChangedNotification:(NSNotification *)note	{
	//NSLog(@"%s",__func__);
/*	NSArray			*portLabelArray = nil;
	
	//	remove the items in the pop-up button
	[outputDestinationButton removeAllItems];
	//	get an array of the out port labels
	portLabelArray = [manager outPortLabelArray];
	//	push the labels to the pop-up button of destinations
	[outputDestinationButton addItemsWithTitles:portLabelArray];*/
}


/*
 @interface OSCMessage : NSObject <NSCopying> {
 NSString			*address;	//!<The address this message is being sent to.  does NOT include any OSC query stuff!  this is literally just the address of the destination node!
 int					valueCount;	//!<The number of values in this message
 OSCValue			*value;	//!<Only used if 'valueCount' is < 2
 NSMutableArray		*valueArray;//!<Only used if 'valCount' is > 1
 
 NSDate				*timeTag;	//!<Nil, or the NSDate at which this message should be executed.  If nil, assume immediate execution.
 
 BOOL				wildcardsInAddress;	//!<Calculated while OSCMessage is being parsed or created.  Used to expedite message dispatch by allowing regex to be skipped when unnecessary.
 OSCMessageType		messageType;//!<OSCMessageTypeControl by default
 OSCQueryType		queryType;	//!<OSCQueryTypeUnknown by default
 unsigned int		queryTXAddress;	//!<0 by default, set when parsing received data- NETWORK BYTE ORDER.  technically, it's a 'struct in_addr'- this is the IP address from which the message was received.  queries need to send their replies back somewhere!
 unsigned short		queryTXPort;	//!<0 by default, set when parsing received data- NETWORK BYTE ORDER.  this is the port from which the UDP message that created this message was received
 }*/

- (void) receivedOSCMessage:(OSCMessage *)m	{
    // NSLog(@"%@", m);
    id binding = [_bindings objectForKey: m.address];
    if (binding)
    {
        if (m.valueCount == 1)
        {
            id value;
            switch (m.value.type)
            {   case OSCValInt: //!<Integer, -2147483648 to 2147483647
                    value = [NSNumber numberWithLongLong: m.value.intValue]; break;
                    break;

                case OSCValFloat :	//!<Float
                    value = [NSNumber numberWithFloat: m.value.floatValue]; break;
                case OSCValString:	//!<String
                    value = m.value.stringValue; break;
                case OSCValTimeTag:	//!<TimeTag
                    break;
                case OSCVal64Int:	//!<64-bit integer, -9223372036854775808 to 9223372036854775807
                    value = [NSNumber numberWithLongLong: m.value.longLongValue]; break;
                case OSCValDouble:	//!<64-bit float (double)
                    value = [NSNumber numberWithDouble: m.value.doubleValue]; break;
                case OSCValChar:	//!<Char
                    break;
                case OSCValColor:	//!<Color
                    value = m.value.colorValue; break;
                case OSCValMIDI:	//!<MIDI
                    break;
                case OSCValBool:	//!<BOOL
                    value = [NSNumber numberWithBool: m.value.boolValue]; break;
                case OSCValNil:	//!<nil/NULL
                    value = nil; break;
                case OSCValInfinity:	//!<Infinity
                    break;
                case OSCValBlob: //!<Blob- random binary data
                    value = m.value.blobNSData;
                    break;
            }            
            id object = [binding objectForKey:@"object"];
            NSString *keyPath = [binding objectForKey:@"keyPath"];
            /*
            [self willChangeValueForKey: @"bindings"];
            NSMutableDictionary *lastVal = [_lastValues objectForKey: m.address];
            [lastVal setObject:value forKey:@"value"];
            [lastVal setObject:[NSDate date] forKey:@"timestamp"];
            [self didChangeValueForKey: @"bindings"];
*/
            
            [object setValue: value forKey: keyPath];
            
        } else
        {            // più di un valore. un pacchetto? come ci si comporta?
        }
        
        
    }
}

@end
