//
//  VELBridgedView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

@class NSVelvetView;
@protocol VELHostView;
@protocol VELScrollView;

/**
 * Represents a view that can be bridged by Velvet, allowing interoperation with
 * other UI frameworks.
 */
@protocol VELBridgedView <NSObject>
@required

/**
 * @name Geometry Conversion
 */

/**
 * Converts a point from the coordinate system of the window to that of the
 * receiver.
 *
 * @param point A point in the coordinate system of the receiver's window.
 */
- (CGPoint)convertFromWindowPoint:(CGPoint)point;

/**
 * Converts a point from the receiver's coordinate system to that of its window.
 *
 * @param point A point in the coordinate system of the receiver.
 */
- (CGPoint)convertToWindowPoint:(CGPoint)point;

/**
 * Converts a rectangle from the coordinate system of the window to that of the
 * receiver.
 *
 * @param rect A rectangle in the coordinate system of the receiver's window.
 */
- (CGRect)convertFromWindowRect:(CGRect)rect;

/**
 * Converts a rectangle from the receiver's coordinate system to that of its window.
 *
 * @param rect A rectangle in the coordinate system of the receiver.
 */
- (CGRect)convertToWindowRect:(CGRect)rect;

/**
 * @name Layer
 */

/**
 * The layer backing the receiver.
 *
 * This property must never be `nil`.
 */
@property (nonatomic, strong, readonly) CALayer *layer;

/**
 * @name View Hierarchy
 */

/**
 * The view directly or indirectly hosting the receiver, or `nil` if the
 * receiver is not part of a hosted view hierarchy.
 *
 * The receiver or one of its ancestors will be the <[VELHostView guestView]> of
 * this view.
 *
 * Implementing classes may require that this property be of a more specific
 * type.
 *
 * @warning **Important:** This property should not be set except by the
 * <VELHostView> itself.
 */
@property (nonatomic, unsafe_unretained) id<VELHostView> hostView;

/**
 * Returns the receiver's <hostView> or superview, whichever is closer in the
 * hierarchy.
 */
- (id<VELBridgedView>)immediateParentView;

/**
 * Traverses all of the bridged ancestors of the receiver, executing the given
 * block on each one. Returns whether enumeration finished without stopping.
 *
 * An implementation of this method should:
 *  
 *  1. If the receiver has no <immediateParentView>, return `YES`.
 *  2. Invoke the given block with the receiver's <immediateParentView> for
 *  `view`, and a pointer to a boolean `NO` for `stop`.
 *  3. If `stop` was set to `YES` from within the block, return `NO`.
 *  4. Otherwise, re-invoke this method on the <immediateParentView>, passing in
 *  the same block, and return the result.
 *
 * This method should _not_ invoke the given block with the receiver as the
 * argument.
 *
 * @param block A block to execute with each ancestor of the receiver (not
 * including the receiver).
 */
- (BOOL)enumerateAncestorsUsingBlock:(void (^)(id<VELBridgedView> view, BOOL *stop))block;

/**
 * Performs a depth-first traversal of all of the bridged descendants of the
 * receiver, executing the given block on each one. Returns whether enumeration
 * finished without stopping.
 *
 * An implementation of this method should enumerate the receiver's subviews
 * and <[VELHostView guestView]>, and at each view:
 *
 *  1. Invoke the given block, passing in that view for `view`, and a pointer to
 *  a boolean `NO` for `stop`.
 *  2. If `stop` was set to `YES` from within the block, stop enumerating and
 *  return `NO`.
 *  3. Otherwise, re-invoke this method on that view, passing in the same block.
 *  If this invocation returns `NO`, stop enumerating and return `NO`.
 *
 * If the receiver has no subviews or <[VELHostView guestView]>, this method
 * should return `YES`. This method should _not_ invoke the given block with the
 * receiver as the argument.
 *
 * @param block A block to execute with each descendant of the receiver (not
 * including the receiver).
 *
 * @warning **Important:** The order in which subviews are traversed, relative to
 * each other and relative to any <[VELHostView guestView]>, is unspecified.
 */
- (BOOL)enumerateDescendantsUsingBlock:(void (^)(id<VELBridgedView> view, BOOL *stop))block;

/**
 * Invoked any time an ancestor of the receiver has relaid itself out,
 * potentially moving or clipping the receiver relative to one of its ancestor
 * views.
 *
 * @warning **Important:** The receiver _must_ forward this message to all of
 * its subviews and any <[VELHostView guestView]>.
 */
- (void)ancestorDidLayout;

/**
 * Invoked any time the receiver has changed absolute positions in the view
 * hierarchy.
 *
 * This will include, for example, any time the receiver or one of its ancestors
 * changes superviews, changes host views, is reordered within its superview,
 * etc.
 *
 * @warning **Important:** The receiver _must_ forward this message to all of
 * its subviews and any <[VELHostView guestView]>.
 */
- (void)viewHierarchyDidChange;

/**
 * Returns the nearest <NSVelvetView> that is an ancestor of the receiver, or of
 * a view hosting the receiver.
 *
 * Returns `nil` if the receiver is not part of a Velvet-hosted view hierarchy.
 */
- (NSVelvetView *)ancestorNSVelvetView;

/**
 * Walks up the receiver's ancestor views, returning the nearest
 * <VELScrollView>.
 *
 * Returns `nil` if no scroll view is an ancestor of the receiver.
 */
- (id<VELScrollView>)ancestorScrollView;

/**
 * Invoked when the receiver is moving to a new <ancestorNSVelvetView>.
 *
 * @param view The new <NSVelvetView> that will host the receiver, or `nil` if
 * the receiver is being detached from its current <ancestorNSVelvetView>.
 *
 * @warning **Important:** The receiver _must_ forward this message to all of
 * its subviews and any <[VELHostView guestView]>.
 */
- (void)willMoveToNSVelvetView:(NSVelvetView *)view;

/**
 * Invoked when the receiver has moved to a new <ancestorNSVelvetView>.
 *
 * @param view The <NSVelvetView> that was previously hosting the receiver, or
 * `nil` if the receiver was not hosted.
 *
 * @warning **Important:** The receiver _must_ forward this message to all of
 * its subviews and any <[VELHostView guestView]>.
 */
- (void)didMoveFromNSVelvetView:(NSVelvetView *)view;

/**
 * @name Focused State
 */

/**
 * Indicates whether the receiver is focused.
 *
 * The receiver is focused if:
 *
 * - It is hosted directly or indirectly within the most descendant
 *   <VELViewController>.
 * - A subview of that <VELViewController> is currently the first responder.
 *
 * The default value for this property is `NO`.
 */
@property (nonatomic, getter = isFocused) BOOL focused;

/**
 * @name Hit Testing
 */

/**
 * Hit tests the receiver's view hierarchy, returning the <VELBridgedView> which
 * is occupying the given point, or `nil` if there is no such view.
 *
 * This method should only traverse views which are visible and allow user
 * interaction.
 *
 * @param point A point, specified in the coordinate system of the receiver,
 * at which to look for a view.
 */
- (id<VELBridgedView>)descendantViewAtPoint:(CGPoint)point;

/**
 * Returns whether the receiver is occupying the given point.
 *
 * @param point A point, specified in the coordinate system of the receiver.
 */
- (BOOL)pointInside:(CGPoint)point;

@end
