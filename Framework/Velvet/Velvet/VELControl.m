//
//  VELControl.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 30.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELControl.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/VELContext.h>

typedef void (^VELControlActionBlock)(void);

@interface VELControl ()
@property (strong, readonly) NSMutableDictionary *actions;
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

- (id)addAction:(void (^)(void))actionBlock forControlEvents:(VELControlEventMask)eventMask; {
    id action = [actionBlock copy];

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        NSNumber *actionEvents = [self.actions objectForKey:action];
        VELControlEventMask mask = (VELControlEventMask)[actionEvents unsignedIntegerValue];

        // if the action wasn't already in the dictionary, the original mask
        // will be zero anyways
        mask |= eventMask;

        [self.actions setObject:[NSNumber numberWithUnsignedInteger:mask] forKey:action];
    });

    return action;
}

- (void)removeAction:(id)action forControlEvents:(VELControlEventMask)eventMask; {
    dispatch_sync_recursive(self.context.dispatchQueue, ^{
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

            [self.actions enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id action, NSNumber *actionEvents, BOOL *stop){
                VELControlEventMask newMask = [actionEvents unsignedIntegerValue] & (~eventMask);
                [self.actions setObject:[NSNumber numberWithUnsignedInteger:newMask] forKey:action];
            }];
        }
    });
}

- (void)sendActionsForControlEvents:(VELControlEventMask)eventMask; {
    __block NSDictionary *actionsCopy;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        actionsCopy = [self.actions copy];
    });

    for (VELControlActionBlock action in actionsCopy) {
        NSNumber *actionEvents = [actionsCopy objectForKey:action];
        if ([actionEvents unsignedIntegerValue] & eventMask) {
            action();
        }
    }
}

@end
