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

/**
 * A semi-concrete protocol that represents a view that can be bridged by
 * Velvet, allowing interoperation with other UI frameworks.
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
 * Invoked any time an ancestor of the receiver has relaid itself out,
 * potentially moving or clipping the receiver relative to one of its ancestor
 * views.
 *
 * @warning **Important:** The receiver _must_ forward this message to all of
 * its subviews and any <[VELHostView guestView]>.
 */
- (void)ancestorDidLayout;

/**
 * Returns the nearest <NSVelvetView> that is an ancestor of the receiver, or of
 * a view hosting the receiver.
 *
 * Returns `nil` if the receiver is not part of a Velvet-hosted view hierarchy.
 */
- (NSVelvetView *)ancestorNSVelvetView;

/**
 * Walks up the receiver's ancestor views, returning the nearest view that is
 * considered to be a scroll view.
 *
 * Returns `nil` if no scroll view is an ancestor of the receiver.
 *
 * @warning The definition of a "scroll view" may vary across UI frameworks.
 */
- (id<VELBridgedView>)ancestorScrollView;

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
