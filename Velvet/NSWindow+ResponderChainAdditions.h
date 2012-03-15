//
//  NSWindow+ResponderChainAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * The name of the `NSNotification` posted when the window's `firstResponder`
 * changes.
 *
 * The user info dictionary for this notification will contain the following
 * keys:
 *
 * - <VELNSWindowOldFirstResponderKey>
 * - <VELNSWindowNewFirstResponderKey>
 */
extern NSString * const VELNSWindowFirstResponderDidChangeNotification;

/**
 * An `NSNotification` user info key associated with the previous `firstResponder`.
 *
 * This key will be associated with `NSNull` when the old first responder is `nil`.
 */
extern NSString * const VELNSWindowOldFirstResponderKey;

/**
 * An `NSNotification` user info key associated with the new `firstResponder`.
 *
 * This key will be associated with `NSNull` when the new first responder is `nil`.
 */
extern NSString * const VELNSWindowNewFirstResponderKey;

/**
 * Extensions to `NSWindow` that support manipulating the responder chain.
 */
@interface NSWindow (ResponderChainAdditions)
/**
 * Makes the given object the first responder if it is not already reachable
 * through the current responder chain. Returns `YES` if the operation was
 * successful, or if `responder` was already in the responder chain.
 *
 * @param responder The object to make first responder. If this is `nil`, this
 * method behaves like `makeFirstResponder:`.
 */
- (BOOL)makeFirstResponderIfNotInResponderChain:(NSResponder *)responder;
@end
