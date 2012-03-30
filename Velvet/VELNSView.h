//
//  VELNSView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELView.h>
#import <Velvet/VELHostView.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>

/**
 * A view that is responsible for displaying and handling an `NSView` within the
 * normal Velvet view hierarchy.
 *
 * @warning `VELNSView` is powerful, but very fragile, and many of its
 * interactions with AppKit rely upon assumptions, magic, or unspecified
 * behavior. To that end, there are several restrictions on what you can do with
 * `VELNSView`:
 *
 * - *A `VELNSView` must always appear on top of Velvet views.* A `VELNSView`
 * should always appear at the end of a subview list. You should not attempt to
 * add Velvet subviews directly to a `VELNSView`. Instead, if you need Velvet
 * views to appear on top, nest an <NSVelvetView> within the `NSView` and start
 * a new Velvet hierarchy.
 *
 * - *You must not modify the geometry of the hosted `NSView`.* If you need to
 * rearrange or resize the `NSView`, modify the `VELNSView` and it will perform
 * the necessary updates.
 *
 * - *You must not touch the layer of the hosted `NSView`.* If you wish to
 * perform animations or apply other Core Animation effects, use the layer of
 * the `VELNSView`. Note that not all Core Animation features may be available.
 *
 * - *You should not subclass `VELNSView`.* If you need additional features,
 * create a new view class which contains a `VELNSView` instead.
 */
@interface VELNSView : VELView <VELHostView>

/**
 * @name Initialization
 */

/**
 * Initializes the receiver, setting its <guestView> to the given view.
 *
 * The <[VELView frame]> of the receiver will automatically be set to that of
 * `view`.
 *
 * The designated initializer for this class is <[VELView init]>.
 *
 * @param view The view to display in the receiver.
 */
- (id)initWithNSView:(NSView *)view;

/**
 * @name Guest View
 */

/**
 * The view displayed by the receiver.
 *
 * This property is not thread-safe. It must be set from the main thread.
 */
@property (nonatomic, strong) NSView *guestView;
@end
