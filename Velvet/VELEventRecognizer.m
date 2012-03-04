//
//  VELEventRecognizer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELEventRecognizer.h"
#import "VELBridgedView.h"
#import "VELEventRecognizerProtected.h"
#import <objc/runtime.h>

/**
 * The type of block passed to <[VELEventRecognizer addActionUsingBlock:]>.
 */
typedef void (^VELEventRecognizerActionBlock)(VELEventRecognizer *);

/**
 * An associated objects key used to attach an `NSArray` of event recognizers to
 * their view.
 */
static void * const VELAttachedEventRecognizersKey = "VELAttachedEventRecognizers";

@interface VELEventRecognizer ()
/**
 * Stores the blocks for actions registered with <addActionUsingBlock:>.
 *
 * This is a counted set so that the behavior of calling <addActionUsingBlock:>
 * and/or <removeAction:> multiple times with the same block is well-defined.
 */
@property (nonatomic, strong, readonly) NSCountedSet *actions;

/**
 * Attaches the given event recognizer to the given view.
 *
 * If `view` is `nil`, nothing happens.
 *
 * @param recognizer The recognizer to attach.
 * @param view The view to which the recognizer should be attached. This should
 * be the same object as the <[VELEventRecognizer view]> property.
 */
+ (void)addEventRecognizer:(VELEventRecognizer *)recognizer forView:(id<VELBridgedView>)view;

/**
 * Detaches the given event recognizer from the given view.
 *
 * If `view` is `nil`, or the given recognizer is not attached to the given
 * view, nothing happens.
 *
 * @param recognizer The recognizer to detach.
 * @param view The view from which the recognizer should be detached.
 */
+ (void)removeEventRecognizer:(VELEventRecognizer *)recognizer forView:(id<VELBridgedView>)view;

/**
 * Sets the receiver's <state> without going through the normal logic of the
 * <state> property.
 *
 * In particular, this will not pay attention to delayed state changes, or other
 * event recognizers that need to fail first.
 */
- (void)reallySetState:(VELEventRecognizerState)newState;

/**
 * Invokes all of the receiver's <actions>.
 */
- (void)sendAction;
@end

@implementation VELEventRecognizer

#pragma mark Properties

@synthesize view = m_view;
@synthesize state = m_state;
@synthesize enabled = m_enabled;
@synthesize recognizersRequiredToFail = m_recognizersRequiredToFail;
@synthesize delaysEventDelivery = m_delaysEventDelivery;
@synthesize actions = m_actions;

- (BOOL)isActive {
    switch (self.state) {
        case VELEventRecognizerStateBegan:
        case VELEventRecognizerStateChanged:
        case VELEventRecognizerStateEnded:
            return YES;

        default:
            return NO;
    }
}

- (BOOL)isContinuous {
    return NO;
}

- (BOOL)isDiscrete {
    return NO;
}

- (void)setEnabled:(BOOL)enabled {
    if (enabled == m_enabled)
        return;

    m_enabled = enabled;

    if (!m_enabled) {
        if (self.state == VELEventRecognizerStateBegan || self.state == VELEventRecognizerStateChanged) {
            [self reallySetState:VELEventRecognizerStateCancelled];
        }
    }
}

- (void)setState:(VELEventRecognizerState)state {
    if (!self.enabled)
        return;

    // this method should never short-circuit if already in the given state,
    // since every call to this setter should be interpreted as a new transition
    
    // TODO: check dependencies
    [self reallySetState:state];
}

- (void)setView:(id<VELBridgedView>)view {
    if (view == m_view)
        return;

    [[self class] removeEventRecognizer:self forView:m_view];
    m_view = view;
    [[self class] addEventRecognizer:self forView:m_view];
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_actions = [NSCountedSet set];
    m_enabled = YES;

    return self;
}

#pragma mark Attached Recognizers

+ (void)addEventRecognizer:(VELEventRecognizer *)recognizer forView:(id<VELBridgedView>)view; {
    NSParameterAssert(recognizer != nil);

    if (!view)
        return;

    NSArray *existingRecognizers = objc_getAssociatedObject(view, VELAttachedEventRecognizersKey);
    if (!existingRecognizers)
        existingRecognizers = [NSArray array];

    NSAssert(![existingRecognizers containsObject:recognizer], @"Recognizer %@ is already attached to view %@", recognizer, view);
    
    NSArray *newRecognizers = [existingRecognizers arrayByAddingObject:recognizer];
    objc_setAssociatedObject(view, VELAttachedEventRecognizersKey, newRecognizers, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (NSArray *)eventRecognizersForView:(id<VELBridgedView>)view; {
    NSParameterAssert(view != nil);

    return objc_getAssociatedObject(view, VELAttachedEventRecognizersKey);
}

+ (void)removeEventRecognizer:(VELEventRecognizer *)recognizer forView:(id<VELBridgedView>)view; {
    NSParameterAssert(recognizer != nil);

    if (!view)
        return;

    NSArray *existingRecognizers = objc_getAssociatedObject(view, VELAttachedEventRecognizersKey);
    if (!existingRecognizers)
        return;

    NSMutableArray *newRecognizers = [existingRecognizers mutableCopy];
    [newRecognizers removeObjectIdenticalTo:recognizer];

    if (newRecognizers.count == existingRecognizers.count)
        return;
    
    objc_setAssociatedObject(view, VELAttachedEventRecognizersKey, newRecognizers, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark Event Handling

- (void)handleEvent:(NSEvent *)event; {
    // TODO: queue up delayed events
}

#pragma mark States and Transitions

- (void)didTransitionFromState:(VELEventRecognizerState)fromState; {
}

- (void)reset; {
    [self reallySetState:VELEventRecognizerStatePossible];
}

- (void)willTransitionToState:(VELEventRecognizerState)toState; {
}

- (void)reallySetState:(VELEventRecognizerState)newState; {
    BOOL transitionValid = NO;
    VELEventRecognizerState oldState = self.state;

    switch (newState) {
        case VELEventRecognizerStatePossible: {
            transitionValid = !(oldState == VELEventRecognizerStateBegan || oldState == VELEventRecognizerStateChanged);
            break;
        }

        case VELEventRecognizerStateBegan: {
            if (!self.continuous) {
                transitionValid = NO;
                break;
            }

            transitionValid = (oldState == VELEventRecognizerStatePossible);
            break;
        }

        case VELEventRecognizerStateEnded: { // also VELEventRecognizerStateRecognized
            if (self.discrete) {
                transitionValid = (oldState == VELEventRecognizerStatePossible);
                break;
            }

            // else fall through

        case VELEventRecognizerStateChanged:
        case VELEventRecognizerStateCancelled:
            if (!self.continuous) {
                transitionValid = NO;
                break;
            }

            transitionValid = (oldState == VELEventRecognizerStateBegan || oldState == VELEventRecognizerStateChanged);
            break;
        }

        case VELEventRecognizerStateFailed: {
            if (!self.discrete) {
                transitionValid = NO;
                break;
            }

            transitionValid = (oldState == VELEventRecognizerStatePossible);
            break;
        }

        default:
            NSAssert(NO, @"Unrecognized event recognizer state %i", (int)newState);
    }

    if (!transitionValid) {
        NSAssert(NO, @"Invalid transition from state %i to state %i on event recognizer %@", (int)oldState, (int)newState, self);

        // if assertions are disabled, log and return
        NSLog(@"*** Invalid transition from state %i to state %i on event recognizer %@", (int)oldState, (int)newState, self);
        return;
    }

    if (newState == VELEventRecognizerStateEnded || newState == VELEventRecognizerStateCancelled || newState == VELEventRecognizerStateFailed) {
        // move to the Possible state on the next run loop iteration
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reset];
        });
    }

    [self willTransitionToState:newState];
    m_state = newState;
    [self didTransitionFromState:oldState];

    if (self.enabled)
        [self sendAction];
}

#pragma mark Actions

- (id)addActionUsingBlock:(VELEventRecognizerActionBlock)block; {
    NSParameterAssert(block != nil);

    // use a copied version of the block as the opaque 'action' type that we'll
    // store and return
    id action = [block copy];
    [self.actions addObject:action];

    return action;
}

- (void)removeAction:(id)action; {
    NSParameterAssert(action != nil);

    [self.actions removeObject:action];
}

- (void)removeAllActions; {
    [self.actions removeAllObjects];
}

- (void)sendAction; {
    // make a copy, in case any action blocks remove themselves or add new
    // actions
    NSSet *actions = [self.actions copy];
    
    for (VELEventRecognizerActionBlock block in actions) {
        NSUInteger count = [self.actions countForObject:block];

        // invoke the block once for each time it's been registered
        for (NSUInteger i = 0; i < count; ++i) {
            block(self);
        }
    }
}

@end
