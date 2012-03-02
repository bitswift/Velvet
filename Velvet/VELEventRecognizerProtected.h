//
//  VELEventRecognizerProtected.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELEventRecognizer.h>

/**
 * Exposes <VELEventRecognizer> methods that subclasses may override, but that
 * should not be invoked by consumers of the class.
 */
@interface VELEventRecognizer (Protected)

/**
 * @name Recognizer State
 */

/**
 * The current state of the event recognizer.
 *
 * It is undefined behavior to set this property to a state that cannot be
 * validly transitioned to from the previous state.
 */
@property (nonatomic, assign, readwrite) VELEventRecognizerState state;

/**
 * @name Event Handling
 */

/**
 * Overridden to interpret and recognize events.
 *
 * This is invoked every time an `NSEvent` would be sent to the receiver's
 * <[VELEventRecognizer view]> or one of its descendants.
 */
- (void)handleEvent:(NSEvent *)event;

@end
