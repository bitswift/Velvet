//
//  VELView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Velvet/VELGeometry.h>

@class VELContext;
@class NSVelvetView;

/**
 * A layer-backed view. A view hierarchy built using this class must ultimately
 * be hosted in a <NSVelvetView>.
 */
@interface VELView : NSResponder <VELGeometry>

/**
 * @name Initialization
 */

/**
 * Initializes the receiver.
 *
 * In contrast to `NSView` or `UIView`, this is the designated initializer for
 * this class, because the frame that a view is initialized with often says very
 * little about its final frame or layout, and implies that callers should
 * attempt to provide meaningful values. Instead of worrying about geometry at
 * the time of initialization, the <frame> can be set as soon as it is actually
 * appropriate.
 */
- (id)init;

/**
 * @name Geometry
 */

/**
 * The frame of this view, in its superview's coordinate system.
 */
@property (assign) CGRect frame;

/**
 * The drawing region of this view, relative to its <frame>.
 */
@property (assign) CGRect bounds;

/**
 * The center of this view, in its superview's coordinate system.
 */
@property (assign) CGPoint center;

/**
 * Transforms a point from the coordinate system of another view to that of the
 * receiver.
 *
 * @param point The point to transform into the receiver's coordinate system.
 * @param view The view whose coordinate system `point` is represented in.
 *
 * @warning *Important:* The receiver and `view` must be rooted at the same
 * window.
 */
- (CGPoint)convertPoint:(CGPoint)point fromView:(id<VELGeometry>)view;

/**
 * Transforms a point from the coordinate system of the receiver to that of
 * another view.
 *
 * @param point The point in the receiver's coordinate system.
 * @param view The view whose coordinate system `point` should be represented in.
 *
 * @warning *Important:* The receiver and `view` must be rooted at the same
 * window.
 */
- (CGPoint)convertPoint:(CGPoint)point toView:(id<VELGeometry>)view;

/**
 * Transforms a rectangle from the coordinate system of another view to that of
 * the receiver.
 *
 * @param rect The rectangle to transform into the receiver's coordinate system.
 * @param view The view whose coordinate system `rect` is represented in.
 *
 * @warning *Important:* The receiver and `view` must be rooted at the same
 * window.
 */
- (CGRect)convertRect:(CGRect)rect fromView:(id<VELGeometry>)view;

/**
 * Transforms a rectangle from the coordinate system of the receiver to that of
 * another view.
 *
 * @param rect The rectangle in the receiver's coordinate system.
 * @param view The view whose coordinate system `rect` should be represented in.
 *
 * @warning *Important:* The receiver and `view` must be rooted at the same
 * window.
 */
- (CGRect)convertRect:(CGRect)rect toView:(id<VELGeometry>)view;

/**
 * @name View Hierarchy
 */

/**
 * The subviews of the receiver, with the first object being the back-most view.
 * This array can be replaced to completely change the subviews displayed by the
 * receiver.
 */
@property (copy) NSArray *subviews;

/**
 * The immediate superview of the receiver, or `nil` if the receiver is a root
 * view.
 *
 * To obtain the <NSVelvetView> that the receiver is hosted in, you must use
 * <hostView> instead.
 */
@property (readonly, weak) VELView *superview;

/**
 * The <NSVelvetView> that is hosting the furthest ancestor of the receiver.
 */
@property (readonly, weak) NSVelvetView *hostView;

/**
 * The window in which the receiver is displayed.
 */
@property (readonly, weak) NSWindow *window;

/**
 * Returns the closest ancestor that is shared by the receiver and another view,
 * or `nil` if there is no such view.
 *
 * @param view The view to find a common ancestor of, along with the receiver.
 */
- (VELView *)ancestorSharedWithView:(VELView *)view;

/**
 * Returns the closest ancestor scroll view containing the receiver (including
 * the receiver itself), or `nil` if there is no such view.
 *
 * This may return an `NSScrollView`, a <VELScrollView>, or a custom class. This
 * method will search both Velvet and AppKit hierarchies.
 */
- (id)ancestorScrollView;

/**
 * Returns whether the receiver is `view` or a descendant thereof.
 *
 * @param view The root of the view hierarchy in which to search for the
 * receiver.
 */
- (BOOL)isDescendantOfView:(VELView *)view;

/**
 * Removes the receiver from its <superview>. If the receiver has no superview,
 * nothing happens.
 */
- (void)removeFromSuperview;

/**
 * @name Layout
 */

/**
 * Lays out subviews.
 *
 * The default implementation of this method does nothing.
 */
- (void)layoutSubviews;

/**
 * Calculates and returns the preferred size of the receiver that fits within
 * a constraining size (if possible).
 *
 * This method should return the size that best fits its subviews in the
 * constraint available. If the receiver cannot fit in the constrained size, it
 * should return the smallest size that it will fit in.
 *
 * The default implementation of this method returns the size of the receiver's
 * <bounds>.
 *
 * @param constraint The size to which the receiver should be constrained. If
 * this is `CGSizeZero`, the receiver should return its generally preferred
 * size.
 */
- (CGSize)sizeThatFits:(CGSize)constraint;

/**
 * @name Drawing
 */

/**
 * If the view's appearance is not provided by its layer, this method should
 * draw the view into the current graphics context.
 *
 * The default implementation of this method does nothing.
 *
 * @param rect The rectangle of the receiver which needs redrawing, specified in
 * the receiver's coordinate system.
 */
- (void)drawRect:(CGRect)rect;

/**
 * @name Event Handling
 */

/**
 * Returns the farthest descendant of the receiver in the view hierarchy (including itself)
 * that contains a given point.
 *
 * Returns `nil` if `point` lies completely outside the receiver.
 *
 * @param point A point specified in the coordinate system of the receiver.
 */
- (VELView *)hitTest:(CGPoint)point;

/**
 * @name Core Animation Layer
 */

/**
 * The class of Core Animation layer to use for this view's backing store.
 */
+ (Class)layerClass;

/**
 * The layer backing this view. This will be an instance of the <layerClass>
 * specified by the receiver's class.
 */
@property (readonly, strong) CALayer *layer;

/**
 * @name Rendering Context
 */

/**
 * The rendering context for the receiver.
 *
 * This is set when the receiver is added to a <VELView> or <NSVelvetView>. This
 * will be the same object for all views rooted at the same <NSVelvetView>.
 *
 * @warning *Important:* The receiver should not be used from a different <VELContext>.
 */
@property (readonly, strong) VELContext *context;
@end
