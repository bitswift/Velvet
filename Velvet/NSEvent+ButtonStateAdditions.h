//
//  NSEvent+ButtonStateAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 08.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Extensions to `NSEvent` to retrieve mouse or tablet button state.
 */
@interface NSEvent (ButtonStateAdditions)

/**
 * @name Getting Mouse Button State
 */

/**
 * Whether the receiver has enough information to return valid values for
 * <mouseButtonStateMask> and <mouseButtonStateChangedMask>.
 */
@property (nonatomic, readonly) BOOL hasMouseButtonState;

/**
 * If the receiver is an event that has information about which mouse buttons
 * are currently pressed, this will return a bitmask containing that
 * information. Otherwise, returns zero.
 *
 * Bit zero represents whether the first mouse button is down, bit one is
 * whether the second mouse button is down, etc.
 *
 * This property works for more event types than `-[NSEvent buttonMask]`.
 */
@property (nonatomic, readonly) NSUInteger mouseButtonStateMask;

/**
 * If the receiver is an event that has information about mouse buttons changing
 * state, this will return a bitmask containing that information. Otherwise,
 * returns zero.
 *
 * Bit zero represents whether the first mouse button changed state, bit one is
 * whether the second mouse button changed state, etc.
 */
@property (nonatomic, readonly) NSUInteger mouseButtonStateChangedMask;

/**
 * @name Converting to Mouse Events
 */

/**
 * Creates and returns an array of `NSEvent` objects that represent the changes
 * in mouse button state encapsulated by the receiver. If <hasMouseButtonState>
 * is `NO`, this method returns `nil`.
 *
 * @note The returned events will not be associated with an application window.
 */
- (NSArray *)correspondingMouseEvents;

@end
