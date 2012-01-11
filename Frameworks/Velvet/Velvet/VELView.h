//
//  VELView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Velvet/VELBridgedView.h>

@class NSVelvetView;

/**
 * Defines how a <VELView> automatically resizes. These flags can be bitwise
 * ORed together to combine behaviors.
 */
typedef enum {
    /**
     * The view does not automatically resize.
     */
    VELViewAutoresizingNone = kCALayerNotSizable,

    /**
     * The left margin between the view and its superview is flexible.
     */
    VELViewAutoresizingFlexibleLeftMargin = kCALayerMinXMargin,

    /**
     * The view's width is flexible.
     */
    VELViewAutoresizingFlexibleWidth = kCALayerWidthSizable,

    /**
     * The right margin between the view and its superview is flexible.
     */
    VELViewAutoresizingFlexibleRightMargin = kCALayerMaxXMargin,

    /**
     * The top margin between the view and its superview is flexible.
     */
    VELViewAutoresizingFlexibleTopMargin = kCALayerMaxYMargin,

    /**
     * The view's height is flexible.
     */
    VELViewAutoresizingFlexibleHeight = kCALayerHeightSizable,

    /**
     * The bottom margin between the view and its superview is flexible.
     */
    VELViewAutoresizingFlexibleBottomMargin = kCALayerMinYMargin
} VELViewAutoresizingMask;

/**
 * Defines how the content of a <VELView> is adjusted when its size changes.
 */
typedef enum {
    /**
     * Scale the content to fit the new size, changing its aspect ratio if
     * necessary.
     */
    VELViewContentModeScaleToFill,

    /**
     * Scale the content to fit within the new size, preserving its aspect
     * ratio. Any remaining area is transparent.
     */
    VELViewContentModeScaleAspectFit,

    /**
     * Scale the content to fill the new size, preserving its aspect ratio.
     * Portions of the content may be clipped to the visible area.
     */
    VELViewContentModeScaleAspectFill,

    /**
     * Redraw the content for the new size, by invoking <drawRect:>.
     */
    VELViewContentModeRedraw,

    /**
     * Center the content in the new size, without resizing the content iself.
     */
    VELViewContentModeCenter,

    /**
     * Keep the content centered at the top in the new size, without resizing
     * the content iself.
     */
    VELViewContentModeTop,

    /**
     * Keep the content centered at the bottom in the new size, without resizing
     * the content itself.
     */
    VELViewContentModeBottom,

    /**
     * Keep the content centered at the left in the new size, without resizing
     * the content itself.
     */
    VELViewContentModeLeft,

    /**
     * Keep the content centered at the right in the new size, without resizing
     * the content itself.
     */
    VELViewContentModeRight,

    /**
     * Keep the content in the top-left of the new size, without resizing the
     * content itself.
     */
    VELViewContentModeTopLeft,

    /**
     * Keep the content in the top-right of the new size, without resizing the
     * content itself.
     */
    VELViewContentModeTopRight,

    /**
     * Keep the content in the bottom-left of the new size, without resizing the
     * content itself.
     */
    VELViewContentModeBottomLeft,

    /**
     * Keep the content in the bottom-right of the new size, without resizing
     * the content itself.
     */
    VELViewContentModeBottomRight
} VELViewContentMode;

/**
 * A layer-backed view. A view hierarchy built using this class must ultimately
 * be hosted in a <NSVelvetView>.
 *
 * If a view has a view controller, the view's next responder is the view
 * controller. Otherwise, the next responder is set as follows:
 * 
 *  1. If the view has a <superview>, the superview is the next responder.
 *  2. If the view has a <hostView>, the host view is the next responder.
 *  3. Otherwise, there is no next responder.
 */
@interface VELView : NSResponder <VELBridgedView>

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
 * Initializes the receiver, setting its initial frame.
 *
 * @param frame The initial frame for the receiver.
 */
- (id)initWithFrame:(CGRect)frame;

/**
 * @name Geometry
 */

/**
 * The frame of this view, in its superview's coordinate system.
 */
@property (nonatomic, assign) CGRect frame;

/**
 * The drawing region of this view, relative to its <frame>.
 */
@property (nonatomic, assign) CGRect bounds;

/**
 * The center of this view, in its superview's coordinate system.
 */
@property (nonatomic, assign) CGPoint center;

/**
 * A transform applied to the receiver, relative to the center of its <bounds>.
 *
 * This will get and set the underlying `CATransform3D` of the receiver's
 * <layer>.
 *
 * @warning *Important:* When reading the property, if the layer has an existing
 * 3D transform that cannot be represented as an affine transform,
 * `CGAffineTransformIdentity` is returned.
 */
@property (nonatomic, assign) CGAffineTransform transform;

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
- (CGPoint)convertPoint:(CGPoint)point fromView:(id<VELBridgedView>)view;

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
- (CGPoint)convertPoint:(CGPoint)point toView:(id<VELBridgedView>)view;

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
- (CGRect)convertRect:(CGRect)rect fromView:(id<VELBridgedView>)view;

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
- (CGRect)convertRect:(CGRect)rect toView:(id<VELBridgedView>)view;

/**
 * @name View Hierarchy
 */

/**
 * The subviews of the receiver, with the first object being the back-most view.
 * This array can be replaced to completely change the subviews displayed by the
 * receiver.
 */
@property (nonatomic, copy) NSArray *subviews;

/**
 * The immediate superview of the receiver, or `nil` if the receiver is a root
 * view.
 *
 * To obtain the <NSVelvetView> that the receiver is hosted in, you must use
 * <hostView> instead.
 */
@property (nonatomic, readonly, weak) VELView *superview;

/**
 * The <NSVelvetView> that is hosting the furthest ancestor of the receiver.
 */
@property (nonatomic, readonly, weak) NSVelvetView *hostView;

/**
 * The window in which the receiver is displayed.
 */
@property (nonatomic, readonly, weak) NSWindow *window;

/**
 * Adds the given view as a subview of the receiver, on top of the other
 * subviews.
 *
 * @param view The view to add as a subview. This view is removed from its
 * current superview before being added.
 */
- (void)addSubview:(VELView *)view;

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
 * Invoked after the receiver has moved to a new <superview>, which may be
 * `nil`.
 *
 * The default implementation of this method notifies all subviews of the
 * event.
 *
 * This method can be overridden by subclasses to perform additional
 * actions when the superview changes. Subclasses must call the `super`
 * implementation.
 *
 * @param oldSuperview The view that was previously the superview of the
 * receiver, or `nil` if the receiver had no superview previously.
 */
- (void)didMoveFromSuperview:(VELView *)oldSuperview;

/**
 * Invoked after the receiver has moved to a new <window>, which may be `nil`.
 *
 * The default implementation of this method notifies all subviews of the
 * event.
 *
 * This method can be overridden by subclasses to perform additional
 * actions when the window changes. Subclasses must call the `super`
 * implementation.
 *
 * @param oldWindow The window that previously contained the receiver, or
 * `nil` if the receiver was not in a window previously.
 */
- (void)didMoveFromWindow:(NSWindow *)oldWindow;

/**
 * Invoked immediately before the receiver moves to a new superview.
 *
 * The default implementation of this method notifies all subviews of the
 * event.
 *
 * This method can be overridden by subclasses to perform additional
 * actions when the superview changes. Subclasses must call the `super`
 * implementation.
 *
 * @param superview The view that will become the superview of the
 * receiver, or `nil` if the receiver is being removed from its superview.
 */
- (void)willMoveToSuperview:(VELView *)superview;

/**
 * Invoked immediately before the receiver moves to a new window.
 *
 * The default implementation of this method notifies all subviews of the
 * event.
 *
 * This method can be overridden by subclasses to perform additional
 * actions when the window changes. Subclasses must call the `super`
 * implementation.
 *
 * @param window The window that will host the receiver, or `nil` if the
 * receiver is being removed from its window.
 */
- (void)willMoveToWindow:(NSWindow *)window;

/**
 * @name Layout
 */

/**
 * Defines how the view should be resized when the bounds of its <superview>
 * changes.
 */
@property (nonatomic, assign) VELViewAutoresizingMask autoresizingMask;

/**
 * Whether subviews are clipped to the receiver's <bounds>.
 *
 * If set to `NO`, subviews will remain visible when positioned outside of the
 * receiver's <bounds>.
 *
 * @warning **Important:** Setting this property to `NO` will not affect event
 * handling. Events that are outside of the bounds of the receiver will still be
 * ignored by default.
 */
@property (nonatomic, assign) BOOL clipsToBounds;

/**
 * Lays out subviews.
 *
 * The default implementation of this method does nothing.
 */
- (void)layoutSubviews;

/**
 * Whether the receiver is waiting to lay out its subviews.
 */
- (BOOL)needsLayout;

/**
 * Marks the receiver as needing layout.
 */
- (void)setNeedsLayout;

/**
 * Calculates and returns the preferred size of the receiver that fits within
 * a constraining size (if possible).
 *
 * This method should return the size that best fits its subviews in the
 * constraint available. If the receiver cannot fit in the constrained size, it
 * should return the smallest size that it will fit in.
 *
 * The default implementation of this method returns the smallest rectangle
 * that can contain all its subviews.
 *
 * @param constraint The size to which the receiver should be constrained. If
 * either dimension of this size is zero, the receiver is not constrained in
 * that dimension. If both dimensions are zero (the size is `CGSizeZero`), the
 * receiver should return its generally preferred size.
 */
- (CGSize)sizeThatFits:(CGSize)constraint;

/**
 * Expands or shrinks the receiver's <bounds> to its preferred size, as defined
 * by <sizeThatFits:>.
 *
 * The receiver is sized around its <center>.
 *
 * You should not override this method. Implement <sizeThatFits:> instead.
 */
- (void)centeredSizeToFit;

/**
 * @name Drawing
 */

/**
 * The opacity of the receiver.
 */
@property (nonatomic, assign) CGFloat alpha;

/**
 * Whether the receiver is hidden.
 */
@property (nonatomic, assign, getter = isHidden) BOOL hidden;

/**
 * Whether the clear the view's bounds before drawing.
 *
 * If this is set to `YES`, the rectangle passed in to <drawRect:> has been
 * cleared to transparent black. If `NO`, the view is expected to fill the
 * entire rectangle with its drawing (perhaps including transparency).
 *
 * The default value of this property is `YES`. Setting this to `NO` can
 * dramatically speed up rendering if the view's rendering fills its bounds.
 */
@property (nonatomic, assign) BOOL clearsContextBeforeDrawing;

/**
 * The background color of the receiver.
 *
 * The default value for this property is `nil`, meaning that no background is
 * automatically drawn.
 */
@property (nonatomic, strong) NSColor *backgroundColor;

/**
 * Whether the receiver is opaque.
 *
 * If `YES`, the view's content must completely fill its bounds and contain no
 * transparency, allowing the rendering system to skip any blending of this view
 * with content below it. If `NO`, the view is rendered normally.
 *
 * The default value for this property is `NO` (unlike `UIView`).
 */
@property (nonatomic, assign, getter = isOpaque) BOOL opaque;

/**
 * Determines how the content of the view is adjusted when its <bounds> changes.
 *
 * The default value for this property depends on whether the class (or one of
 * its superclasses) reimplements <drawRect:>. If <drawRect:> is reimplemented,
 * `VELViewContentModeRedraw` will be used as the default (unlike `UIView`);
 * otherwise, `VELViewContentModeScaleToFill` will be used.
 *
 * Subclasses may initialize this to a different value.
 */
@property (nonatomic, assign) VELViewContentMode contentMode;

/**
 * Defines which portions of the receiver's content are stretchable.
 *
 * This controls how a view's content is stretched to fill its bounds, such as
 * during an animation, or if the <contentMode> is
 * `VELViewContentModeScaleToFill`.
 *
 * This property is specified in the unit coordinate space, where the values of
 * the rectangle are normalized from zero to one, inclusive. Specifying a value
 * of 0.5, for instance, indicates a span that is half of the size of the view
 * in that dimension.
 *
 * The default value for this property is a rectangle starting at `(0, 0)` and
 * extending to `(1, 1)`, indicating that the entirety of the view's content is
 * stretchable.
 */
@property (nonatomic, assign) CGRect contentStretch;

/**
 * If the view's appearance is not provided by its layer, this method should
 * draw the view into the current `NSGraphicsContext`.
 *
 * The default implementation of this method does nothing.
 *
 * @param rect The rectangle of the receiver which needs redrawing, specified in
 * the receiver's coordinate system.
 */
- (void)drawRect:(CGRect)rect;

/**
 * Whether the receiver needs to be redrawn.
 */
- (BOOL)needsDisplay;

/**
 * Marks the receiver as needing to be redrawn.
 */
- (void)setNeedsDisplay;

/**
 * Marks the specified region of the receiver as needing to be redrawn.
 *
 * @param rect The rectangle to invalidate, specified in the coordinate system
 * of the receiver.
 */
- (void)setNeedsDisplayInRect:(CGRect)rect;

/**
 * @name Event Handling
 */

/**
 * Whether user interaction is enabled for the receiver.
 *
 * If user interaction is not enabled, `NSResponder` messages are not sent to
 * the receiver, and event handling behaves as if the view is not there.
 *
 * The default is `YES`. Subclasses may initialize this to a different value.
 */
@property (nonatomic, assign, getter = isUserInteractionEnabled) BOOL userInteractionEnabled;

/**
 * @name Animations
 */

/**
 * Animates changes to one or more views using the default duration.
 *
 * @param animations A block containing the changes to make that should be
 * animated.
 */
+ (void)animate:(void (^)(void))animations;

/**
 * Animates changes to one or more views using the default duration.
 *
 * @param animations A block containing the changes to make that should be
 * animated.
 * @param completionBlock A block to execute when the effect of the animation
 * completes.
 */
+ (void)animate:(void (^)(void))animations completion:(void (^)(void))completionBlock;

/**
 * Animates changes to one or more views with a custom duration.
 *
 * @param duration The length of the animation.
 * @param animations A block containing the changes to make that should be
 * animated.
 */
+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations;

/**
 * Animates changes to one or more views with a custom duration.
 *
 * @param duration The length of the animation.
 * @param animations A block containing the changes to make that should be
 * animated.
 * @param completionBlock A block to execute when the effect of the animation
 * completes.
 */
+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(void))completionBlock;

/**
 * Whether changes are currently being added to an animation.
 *
 * This is not whether an animation is currently in progress, but whether the
 * calling code is running from an animation block.
 */
+ (BOOL)isAnimating;

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
@property (nonatomic, readonly, strong) CALayer *layer;
@end
