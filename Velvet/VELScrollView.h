//
//  VELScrollView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.02.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELBridgedView.h>

/**
 * Represents any kind of scroll view.
 */
@protocol VELScrollView <VELBridgedView>
@required

/**
 * @name Scrolling
 */

/**
 * Scrolls the receiver such that the visible rectangle originates at the given
 * point. This method should enable any applicable animations.
 *
 * @param point A point, specified in the receiver's coordinate system, that
 * should be the new origin for the scroll view's content.
 */
- (void)scrollToPoint:(CGPoint)point;

/**
 * Scrolls the receiver the minimum amount required to ensure that the given
 * rectangle is made visible. This method should enable any applicable
 * animations.
 *
 * If the given rectangle is already visible in the scroll view, nothing
 * happens. If the rectangle is larger than the size of the scroll view, as much
 * of it as possible should be made visible.
 *
 * This method is named to avoid method signature conflicts with AppKit.
 *
 * @param rect A rectangle, specified in the receiver's coordinate system, that
 * should be made visible.
 */
- (void)scrollToIncludeRect:(CGRect)rect;

@end
