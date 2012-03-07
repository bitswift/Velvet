//
//  VELKeyPressEventRecognizer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 06.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELKeyPressEventRecognizer.h"
#import "VELEventRecognizerProtected.h"
#import "VELKeyPress.h"

@interface VELKeyPressEventRecognizer ()
/**
 * Contains <VELKeyPress> objects representing the key presses that have been
 * received so far.
 */
@property (nonatomic, strong, readonly) NSMutableArray *receivedKeyPresses;
@end

@implementation VELKeyPressEventRecognizer

#pragma mark Properties

@synthesize keyPressesToRecognize = m_keyPressesToRecognize;
@synthesize receivedKeyPresses = m_receivedKeyPresses;

- (BOOL)isDiscrete {
    return YES;
}

#pragma mark Initialization

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_receivedKeyPresses = [NSMutableArray array];
    return self;
}

#pragma mark Event Handling

- (BOOL)handleEvent:(NSEvent *)event; {
    if (event.type != NSKeyDown || [event isARepeat])
        return NO;

    VELKeyPress *keyPress = [[VELKeyPress alloc] initWithEvent:event];
    if (!keyPress)
        return NO;

    [self.receivedKeyPresses addObject:keyPress];

    __block BOOL failed = NO;
    [self.receivedKeyPresses enumerateObjectsUsingBlock:^(VELKeyPress *keyPress, NSUInteger index, BOOL *stop){
        if (index < self.keyPressesToRecognize.count && [[self.keyPressesToRecognize objectAtIndex:index] isEqual:keyPress])
            return;

        // got an event that's invalid, fail to recognize
        failed = YES;
        *stop = YES;
    }];

    // if we failed or are not done recognizing yet
    if (failed) {
        self.state = VELEventRecognizerStateFailed;
        return NO;
    }
    
    [super handleEvent:event];

    if (self.receivedKeyPresses.count < self.keyPressesToRecognize.count) {
        return YES;
    }

    NSAssert(self.receivedKeyPresses.count == self.keyPressesToRecognize.count, @"Expected received key presses (%u) to equal number of key presses to recognize (%u)", (unsigned)self.receivedKeyPresses.count, (unsigned)self.keyPressesToRecognize.count);

    // recognized all events (we already checked the objects themselves
    // in the above loop)
    self.state = VELEventRecognizerStateRecognized;
    return YES;
}

#pragma mark Transitions and States

- (void)reset; {
    [super reset];
    [self.receivedKeyPresses removeAllObjects];
}

@end
