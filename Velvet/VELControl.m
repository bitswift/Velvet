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

/*
 * Updates the <selected> property, and sends the corresponding action messages
 * with `event` as the underlying event.
 *
 * @param selected The new value for <selected>.
 * @param event The event that triggered the change in selected state.
 */
- (void)setSelected:(BOOL)selected event:(NSEvent *)event;
@end

@implementation VELControl

#pragma mark Properties

@synthesize actions = m_actions;
@synthesize selected = m_selected;
@synthesize becomesSelectedOnMouseDown = m_becomesSelectedOnMouseDown;

- (void)setSelected:(BOOL)selected {
    [self setSelected:selected event:nil];
}

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
    if (self.becomesSelectedOnMouseDown)
        self.selected = YES;
}

- (void)mouseUp:(NSEvent *)theEvent {
    CGPoint point = [self convertFromWindowPoint:[theEvent locationInWindow]];
    if (![self pointInside:point])
        return;

    [self sendActionsForControlEvents:VELControlEventClicked event:theEvent];

    if (theEvent.clickCount > 0 && (theEvent.clickCount % 2) == 0) {
        [self sendActionsForControlEvents:VELControlEventDoubleClicked event:theEvent];
    }
}

- (void)setSelected:(BOOL)selected event:(NSEvent *)event {
    if (selected == m_selected)
        return;

    if ((m_selected = selected))
        [self sendActionsForControlEvents:VELControlEventSelected];
    else
        [self sendActionsForControlEvents:VELControlEventDeselected];
}

@end
