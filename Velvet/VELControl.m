//
//  VELControl.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 30.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELControl.h"

typedef void (^VELControlActionBlock)(NSEvent *);

@interface VELControl ()
/*
 * All of the action handlers registered on the receiver.
 *
 * The keys in this dictionary will be the blocks, and the values will be
 * `NSNumber` objects that represent the event mask each block is registered
 * for.
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *actions;
@end

@implementation VELControl

#pragma mark Properties

@synthesize actions = m_actions;
@synthesize selected = m_selected;

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_actions = [[NSMutableDictionary alloc] init];
    return self;
}

#pragma mark Event Dispatch

- (id)addActionForControlEvents:(VELControlEventMask)eventMask usingBlock:(VELControlActionBlock)actionBlock; {
    id action = [actionBlock copy];

    NSNumber *actionEvents = [self.actions objectForKey:action];
    VELControlEventMask mask = (VELControlEventMask)[actionEvents unsignedIntegerValue];

    // if the action wasn't already in the dictionary, the original mask
    // will be zero anyways
    mask |= eventMask;

    [self.actions setObject:[NSNumber numberWithUnsignedInteger:mask] forKey:action];
    return action;
}

- (void)removeAction:(id)action forControlEvents:(VELControlEventMask)eventMask; {
    if (action) {
        NSNumber *actionEvents = [self.actions objectForKey:action];
        if (!actionEvents)
            return;

        VELControlEventMask newMask = [actionEvents unsignedIntegerValue] & (~eventMask);
        if (newMask) {
            [self.actions setObject:[NSNumber numberWithUnsignedInteger:newMask] forKey:action];
        } else {
            [self.actions removeObjectForKey:action];
        }
    } else {
        if (eventMask == VELControlAllEvents) {
            [self.actions removeAllObjects];
            return;
        }

        [[self.actions copy] enumerateKeysAndObjectsUsingBlock:^(id action, NSNumber *actionEvents, BOOL *stop){
            VELControlEventMask newMask = [actionEvents unsignedIntegerValue] & (~eventMask);
            [self.actions setObject:[NSNumber numberWithUnsignedInteger:newMask] forKey:action];
        }];
    }
}

- (void)sendActionsForControlEvents:(VELControlEventMask)eventMask; {
    [self sendActionsForControlEvents:eventMask event:nil];
}

- (void)sendActionsForControlEvents:(VELControlEventMask)eventMask event:(NSEvent *)event; {
    // copy actions in case any handler wants to remove it
    for (VELControlActionBlock action in [self.actions copy]) {
        NSNumber *actionEvents = [self.actions objectForKey:action];
        if ([actionEvents unsignedIntegerValue] & eventMask) {
            action(event);
        }
    }
}

#pragma mark Event Handling

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)mouseDown:(NSEvent *)event {
    [self sendActionsForControlEvents:VELControlEventMouseDown event:event];
}

- (void)mouseDragged:(NSEvent *)event {
    [self sendActionsForControlEvents:VELControlEventMouseDrag event:event];
}

- (void)mouseUp:(NSEvent *)event {
    CGPoint point = [self convertFromWindowPoint:[event locationInWindow]];

    if ([self pointInside:point]) {
        [self sendActionsForControlEvents:VELControlEventMouseUpInside event:event];

        if (event.clickCount > 0 && (event.clickCount % 2) == 0) {
            [self sendActionsForControlEvents:VELControlEventDoubleClicked event:event];
        }
    } else {
        [self sendActionsForControlEvents:VELControlEventMouseUpOutside event:event];
    }
}

@end
