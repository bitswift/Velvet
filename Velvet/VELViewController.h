//
//  VELViewController.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 21.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VELView;

/**
 * A controller responsible for managing the lifecycle of a <VELView> and
 * presenting it on screen.
 *
 * A view controller is the next responder for its view. A view controller's
 * next responder is set as follows:
 *
 *  1. If the <view> has a <[VELView superview]>, the superview is the next
 *  responder.
 *  2. If the <view> has a <[VELBridgedView hostView]>, the host view is the
 *  next responder.
 *  3. Otherwise, there is no next responder.
 *
 * Upon deallocation, a `VELViewController` instance automatically removes undo
 * actions targeting itself from any `-[NSResponder undoManager]` and removes itself
 * as an observer from the default `NSNotificationCenter`.
 */
@interface VELViewController : NSResponder

/**
 * @name Managing the View
 */

/**
 * The view managed and presented by this view controller.
 *
 * If no view has been set up when this property is read, <loadView> is invoked
 * to create one, and the new view is returned.
 */
@property (nonatomic, strong, readonly) VELView *view;

/**
 * Whether a <view> has been loaded.
 *
 * This property, unlike <view>, can be queried without a view automatically
 * being created.
 */
@property (nonatomic, readonly, getter = isViewLoaded) BOOL viewLoaded;

/**
 * Invoked to load the <view> for the first time.
 *
 * The default implementation of this method creates a blank view with a frame
 * of `CGRectZero`.
 *
 * This method should never be explicitly called. It can be overridden by
 * subclasses to perform additional work upon view load.
 */
- (VELView *)loadView;

/**
 * Invoked immediately after the receiver's <view> has been unloaded from memory
 * and set to `nil`.
 *
 * This method should be used for clearing out strong references to data that is
 * no longer needed once the view has been destroyed. By the time this method is invoked,
 * any `weak` references to subviews have already been set to `nil`.
 *
 * Unlike UIKit, this method is guaranteed to always be called before the view
 * controller is destroyed.
 *
 * @note Unlike UIKit, the preferred pattern in Velvet is to use `weak`
 * references for all subviews, so that they can be automatically cleaned up
 * when the view is destroyed.
 */
- (void)viewDidUnload;

/**
 * Invoked immediately before the receiver's <view> has been unloaded from
 * memory and set to `nil`.
 *
 * This is an appropriate place to unregister subviews from notifications and
 * perform other cleanup that can only be done with valid references.
 *
 * Unlike UIKit, this method is guaranteed to always be called before the view
 * controller is destroyed.
 */
- (void)viewWillUnload;

/**
 * @name View Presentation
 */

/**
 * Invoked immediately before the receiver's <view> is about to be added to
 * a window.
 *
 * The view will not yet have a superview when this method is invoked.
 */
- (void)viewWillAppear;

/**
 * Invoked immediately after the receiver's <view> has been added to a window.
 *
 * The view will have a superview by the time this method is invoked, and will
 * have been added to a window.
 */
- (void)viewDidAppear;

/**
 * Invoked immediately before the receiver's <view> is about to disappear from
 * the window.
 *
 * The view will still have a superview and a window when this method is invoked.
 */
- (void)viewWillDisappear;

/**
 * Invoked immediately after the receiver's <view> has disappeared from the
 * window.
 *
 * The view will not have a superview or a window by the time this method is
 * invoked.
 */
- (void)viewDidDisappear;

/**
 * @name View Controller Hierarchy
 */

/**
 * The view controller whose view is the closest ancestor of the receiver's
 * <view>.
 */
@property (nonatomic, weak, readonly) VELViewController *parentViewController;

/**
 * @name Focused State
 */

/**
 * Indicates whether the receiver is focused.
 *
 * The receiver is focused if its view or any of its descendants is currently the first responder.
 *
 * The default value for this property is `NO`.
 */
@property (nonatomic, getter = isFocused, readonly) BOOL focused;

@end
