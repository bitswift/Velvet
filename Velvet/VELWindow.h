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
 * The name of the `NSNotification` posted when the receiver's `firstResponder`
 * changes.
 *
 * The user info dictionary for this notification will contain the following
 * keys:
 *
 * - <VELWindowFirstResponderDidChangeOldKey>
 * - <VELWindowFirstResponderDidChangeNewKey>
 */
extern NSString * const VELWindowFirstResponderDidChangeNotification;

/**
 * An `NSNotification` user info key associated with the previous
 * `firstResponder`.
 */
extern NSString * const VELWindowFirstResponderDidChangeOldKey;

/**
 * An `NSNotification` user info key associated with the new `firstResponder`.
 */
extern NSString * const VELWindowFirstResponderDidChangeNewKey;

/**
 * An `NSWindow` automatically set up with a Velvet hierarchy.
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
 * Attempts to make a given responder the first responder for the window.
 *
 * Behaves like `-[NSWindow makeFirstResponder:]`.
 *
 * Posts a `VELWindowFirstResponderDidChangeNotification` when the first
 * responder changes.
 *
 * @param responder The responder to set as the window's first responder. `nil`
 * makes the window its first responder.
 */
- (BOOL)makeFirstResponder:(NSResponder *)responder;

@end
