//
//  VELWindow.h
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

@class NSVelvetView;
@class VELView;

/**
 * The name of the `NSNotification` posted when the window's `firstResponder`
 * changes.
 *
 * The user info dictionary for this notification will contain the following
 * keys:
 *
 * - <VELWindowOldFirstResponderKey>
 * - <VELWindowNewFirstResponderKey>
 */
extern NSString * const VELWindowFirstResponderDidChangeNotification;

/**
 * An `NSNotification` user info key associated with the previous `firstResponder`.
 *
 * This key will be associated with `NSNull` when the old first responder is `nil`.
 */
extern NSString * const VELWindowOldFirstResponderKey;

/**
 * An `NSNotification` user info key associated with the new `firstResponder`.
 *
 * This key will be associated with `NSNull` when the new first responder is `nil`.
 */
extern NSString * const VELWindowNewFirstResponderKey;

/**
 * An `NSWindow` automatically set up with a Velvet hierarchy.
 *
 * This class provides a few additional capabilities useful for Velvet
 * applications:
 *
 *  - It fixes a bug where layer tree renderers sometimes don't get re-enabled
 *  after fast user switching.
 *  - It posts a notification (`VELWindowFirstResponderDidChangeNotification`)
 *  when the first responder changes.
 *  - It provides a slow-motion animation mode in Debug builds, which can be
 *  activated by pressing Shift three times while the window has focus.
 */
@interface VELWindow : NSWindow

/**
 * @name Velvet Hosting
 */

/**
 * The content view of the window, hosting a Velvet hierarchy.
 *
 * This must be set to a view which is an instance of <NSVelvetView>.
 */
@property (nonatomic, strong) NSVelvetView *contentView;

/**
 * The root of the Velvet hierarchy in the receiver.
 */
@property (nonatomic, strong) VELView *rootView;

/**
 * @name Responder Chain
 */

/**
 * Attempts to make a given responder the first responder for the window.
 *
 * Behaves like `-[NSWindow makeFirstResponder:]` and posts a
 * `VELWindowFirstResponderDidChangeNotification` when the first responder
 * changes.
 *
 * @param responder The responder to set as the window's first responder. `nil`
 * makes the window its first responder.
 */
- (BOOL)makeFirstResponder:(NSResponder *)responder;

@end
