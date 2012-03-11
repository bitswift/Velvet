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

/**
 * Marks the recognizer as having failed to recognize its event.
 */
- (void)fail;
@end

@implementation VELKeyPressEventRecognizer

#pragma mark Properties

@synthesize keyPressesToRecognize = m_keyPressesToRecognize;
@synthesize receivedKeyPresses = m_receivedKeyPresses;
@synthesize maximumKeyPressInterval = m_maximumKeyPressInterval;

- (BOOL)isDiscrete {
    return YES;
}

#pragma mark Initialization

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_receivedKeyPresses = [NSMutableArray array];

    self.maximumKeyPressInterval = 0.7;
    return self;
}

#pragma mark Event Handling

- (BOOL)handleEvent:(NSEvent *)event; {
    if (event.type == NSKeyDown) {
        if ([event isARepeat])
            return NO;
    } else if (event.type != NSFlagsChanged) {
        return NO;
    }

    VELKeyPress *keyPress = [[VELKeyPress alloc] initWithEvent:event];
    if (!keyPress)
        return NO;

    if (event.type == NSFlagsChanged && (keyPress.modifierFlags & NSDeviceIndependentModifierFlagsMask) == 0) {
        // ignore empty modifier flags, which are basically like KeyUp
        return NO;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fail) object:nil];
    [self.receivedKeyPresses addObject:keyPress];

    __block BOOL failed = NO;
    [self.receivedKeyPresses enumerateObjectsUsingBlock:^(VELKeyPress *keyPress, NSUInteger index, BOOL *stop){
        if (index < self.keyPressesToRecognize.count && [[self.keyPressesToRecognize objectAtIndex:index] isEqual:keyPress])
            return;

        // got an event that's invalid, fail to recognize
        failed = YES;
        *stop = YES;
    }];

    if (failed) {
        [self fail];
        return NO;
    }
    
    [super handleEvent:event];

    if (self.receivedKeyPresses.count < self.keyPressesToRecognize.count) {
        // fail if we don't receive another key press in time
        [self performSelector:@selector(fail) withObject:nil afterDelay:self.maximumKeyPressInterval];
        return YES;
    }

    NSAssert(self.receivedKeyPresses.count == self.keyPressesToRecognize.count, @"Expected received key presses (%u) to equal number of key presses to recognize (%u)", (unsigned)self.receivedKeyPresses.count, (unsigned)self.keyPressesToRecognize.count);

    // recognized all events (we already checked the objects themselves
    // in the above loop)
    self.state = VELEventRecognizerStateRecognized;
    return YES;
}

#pragma mark Transitions and States

- (void)fail; {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fail) object:nil];
    self.state = VELEventRecognizerStateFailed;
}

- (void)reset; {
    [super reset];
    [self.receivedKeyPresses removeAllObjects];
}

@end
