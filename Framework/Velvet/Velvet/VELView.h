//
//  VELView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELResponder.h>
#import <Velvet/VELGeometry.h>

@class VELContext;
@class NSVelvetView;

/**
 * A layer-backed view. A view hierarchy built using this class must ultimately
 * be hosted in a `NSVelvetView`.
 */
@interface VELView : NSResponder <VELGeometry>

/**
 * The frame of this view, in its superview's coordinate system.
 */
@property (assign) CGRect frame;

/**
 * The drawing region of this view, relative to its `frame`.
 */
@property (assign) CGRect bounds;

/**
 * The center of this view, in its superview's coordinate system.
 */
@property (assign) CGPoint center;

/**
 * The layer backing this view. This will be an instance of the `layerClass`
 * specified by the receiver's class.
 */
@property (readonly, strong) CALayer *layer;

/**
 * The subviews of the receiver, with the first object being the back-most view.
 * This array can be replaced to completely change the subviews displayed by the
 * receiver.
 */
@property (copy) NSArray *subviews;

/**
 * The immediate superview of the receiver, or \c nil if the receiver is a root
 * view.
 *
 * @note To obtain the `NSVelvetView` that the receiver is hosted in, you must use
 * `[VELView hostView]` instead.
 */
@property (readonly, weak) VELView *superview;

/**
 * The `NSVelvetView` that is hosting the furthest ancestor of the receiver.
 */
@property (readonly, weak) NSVelvetView *hostView;

/**
 * The window in which the receiver is displayed.
 */
@property (readonly, weak) NSWindow *window;

/**
 * The rendering context for the receiver. This is set when the receiver is
 * added to a `VELView` or `NSVelvetView`. The receiver should not be used from
 * a different `VELContext`.
 *
 * @note This will be the same object for all views rooted at the same
 * `NSVelvetView`.
 */
@property (readonly, strong) VELContext *context;

/**
 * The class of Core Animation layer to use for this view's backing store.
 */
+ (Class)layerClass;

/**
 * Initializes the receiver.
 *
 * In contrast to `NSView` or `UIView`, this is the designated initializer for
 * this class, because the frame that a view is initialized with often says very
 * little about its final frame or layout, and implies that callers should
 * attempt to provide meaningful values. Instead of worrying about geometry at
 * the time of initialization, the #frame can be set as soon as it is actually
 * appropriate.
 */
- (id)init;

/**
 * Returns the closest ancestor that is shared by the receiver and `view`, or
 * `nil` if there is no such view.
 */
- (VELView *)ancestorSharedWithView:(VELView *)view;

/**
 * Returns whether the receiver is `view` or a descendant thereof. This searches
 * all subviews of `view` to find the receiver.
 */
- (BOOL)isDescendantOfView:(VELView *)view;

/**
 * Transforms `point` from the coordinate system of `view` to that of the
 * receiver.
 */
- (CGPoint)convertPoint:(CGPoint)point fromView:(id<VELGeometry>)view;

/**
 * Transforms `point` from the receiver's coordinate system to that of `view`.
 */
- (CGPoint)convertPoint:(CGPoint)point toView:(id<VELGeometry>)view;

/**
 * Transforms `rect` from the coordinate system of `view` to that of the
 * receiver.
 */
- (CGRect)convertRect:(CGRect)rect fromView:(id<VELGeometry>)view;

/**
 * Transforms `rect` from the receiver's coordinate system to that of `view`.
 */
- (CGRect)convertRect:(CGRect)rect toView:(id<VELGeometry>)view;

/**
 * Returns the farthest descendant of the receiver in the view hierarchy (including itself)
 * that contains a specified point, or nil if that point lies completely outside the receiver.
 */
- (VELView *)hitTest:(CGPoint)aPoint;

/**
 * If the view's appearance is not provided by its layer, this method should
 * draw the view into the current graphics context. `rect` is the rectangle of
 * the receiver which needs redrawing, specified in the receiver's coordinate
 * system.
 *
 * The default implementation of this method does nothing.
 */
- (void)drawRect:(CGRect)rect;

/**
 * Removes the receiver from its `superview`. If the receiver has no superview,
 * nothing happens.
 */
- (void)removeFromSuperview;
@end
