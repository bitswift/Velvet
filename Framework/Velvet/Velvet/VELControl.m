//
//  VELControl.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 30.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELControl.h>

typedef void (^VELControlActionBlock)(void);

@interface VELControl ()
@property (nonatomic, strong, readonly) NSMutableDictionary *actions;
@end

@implementation VELControl

#pragma mark Properties

@synthesize actions = m_actions;

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_actions = [[NSMutableDictionary alloc] init];
    return self;
}

#pragma mark Event Dispatch

- (id)addActionForControlEvents:(VELControlEventMask)eventMask usingBlock:(void (^)(void))actionBlock; {
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
    // copy actions in case any handler wants to remove it
    for (VELControlActionBlock action in [self.actions copy]) {
        NSNumber *actionEvents = [self.actions objectForKey:action];
        if ([actionEvents unsignedIntegerValue] & eventMask) {
            action();
        }
    }
}

#pragma mark Event Handling

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)mouseUp:(NSEvent *)theEvent {
    CGPoint point = [self convertFromWindowPoint:[theEvent locationInWindow]];
    if (!CGRectContainsPoint(self.bounds, point))
        return;

    [self sendActionsForControlEvents:VELControlEventClicked];
}

@end
