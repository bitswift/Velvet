//
//  VELKeyPress.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 06.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * Represents a single key press.
 *
 * This class can be used to represent key events, or to check for desired key
 * events, in a more convenient way than using `NSEvent` objects directly.
 */
@interface VELKeyPress : NSObject <NSCoding, NSCopying>

/**
 * @name Initialization
 */

/**
 * Initializes the receiver with the information from the given event, and sets
 * the <event> property.
 *
 * @param event A key event that the returned object should represent.
 */
- (id)initWithEvent:(NSEvent *)event;

/**
 * Initializes the receiver with the given key press information.
 *
 * This is the designated initializer for this class.
 *
 * @param charactersIgnoringModifiers The value for
 * <charactersIgnoringModifiers>.
 * @param modifierFlags The value for <modifierFlags>.
 */
- (id)initWithCharactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers modifierFlags:(NSUInteger)modifierFlags;

/**
 * @name Key Press Information
 */

/**
 * The characters represented by this key press, as if no modifier keys other
 * than Shift applied.
 *
 * See `-[NSEvent charactersIgnoringModifiers]` for more information.
 */
@property (nonatomic, copy, readonly) NSString *charactersIgnoringModifiers;

/**
 * A bitmask describing the modifier keys held down with this key press.
 *
 * The values for this property are the same as those for `-[NSEvent
 * modifierFlags]`.
 */
@property (nonatomic, assign, readonly) NSUInteger modifierFlags;

/**
 * @name Interacting with Events
 */

/**
 * The underlying `NSEvent` object.
 *
 * This will only be set if the receiver was initialized with <initWithEvent:>.
 */
@property (nonatomic, copy, readonly) NSEvent *event;

@end
