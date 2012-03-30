//
//  VELEventRecognizerProtected.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELEventRecognizer.h>

// Exposes <VELEventRecognizer> methods that subclasses may override, but that
// should not be invoked by consumers of the class.
@interface VELEventRecognizer (Protected)
@property (nonatomic, assign, readwrite) VELEventRecognizerState state;

/**
 * @name Recognizer State
 */

/**
 * Updates the current state of the event recognizer.
 *
 * It is undefined behavior to set a state that cannot be validly transitioned
 * to from the existing state.
 *
 * This setter must not be overridden.
 *
 * @param state The new state for the recognizer.
 *
 * @warning Setting this property may not immediately change its value (for
 * example, if there are still outstanding <[VELEventRecognizer
 * recognizersRequiredToFail]>). Use <willTransitionToState:> and
 * <didTransitionFromState:> to be notified of a successful state transition.
 */
- (void)setState:(VELEventRecognizerState)state;

/**
 * Invoked immediately before the receiver transitions to the given state.
 *
 * When this method is invoked, the receiver's <state> will not have been
 * modified yet.
 *
 * @param toState The state being transitioned to.
 */
- (void)willTransitionToState:(VELEventRecognizerState)toState;

/**
 * Invoked immediately after the receiver transitions to the given state.
 *
 * When this method is invoked, the receiver's <state> will have already been
 * updated.
 *
 * @param fromState The state being transitioned from.
 */
- (void)didTransitionFromState:(VELEventRecognizerState)fromState;

/**
 * @name Event Handling
 */

/**
 * Overridden to interpret and recognize events. This method should return
 * whether the given event was handled successfully, even if the receiver has
 * not fully recognized its event yet.
 *
 * This is invoked every time an `NSEvent` would be sent to the receiver's
 * <[VELEventRecognizer view]> or one of its descendants.
 *
 * You should invoke the implementation of `super` if you will return `YES` from
 * this method, but not if you will return `NO`.
 *
 * @param event An event currently being dispatched.
 *
 * @warning Invoking `super` after performing state transitions will result in
 * undefined behavior.
 */
- (BOOL)handleEvent:(NSEvent *)event;

@end
