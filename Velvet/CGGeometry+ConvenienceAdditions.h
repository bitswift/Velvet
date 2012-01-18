//
//  CGGeometry+ConvenienceAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

/*
 * Chops the given amount off of a rectangle's edge, returning the remainder.
 *
 * If `amount` is greater than or equal to the size of the rectangle along the
 * axis being chopped, `CGRectZero` is returned.
 *
 * @param rect The rectangle to chop up.
 * @param amount The amount of points to remove.
 * @param edge The edge from which to chop.
 */
CGRect CGRectChop (CGRect rect, CGFloat amount, CGRectEdge edge);

/*
 * Adds the given amount to a rectangle's edge.
 *
 * @param rect The rectangle to grow.
 * @param amount The amount of points to add.
 * @param edge The edge from which to grow. Growing is always outward (i.e.,
 * using `CGRectMaxXEdge` will increase the width of the rectangle and leave the
 * origin unmodified).
 */
CGRect CGRectGrow (CGRect rect, CGFloat amount, CGRectEdge edge);

/*
 * Returns the largest rectangle that is part of `rect` and not intersected by
 * `subtraction`.
 *
 *  - If `rect` does not intersect `subtraction`, `rect` is returned without
 *  modification.
 *  - If `rect` is equal to `subtraction`, an empty rectangle is returned.
 *  - If `rect` is contained entirely within `subtraction`, `CGRectNull` is
 *  returned.
 *
 * If the subtraction results in multiple rectangles of equal size, the
 * rectangle starting closest to `(0, 0)` is the one returned.
 *
 * @param rect The rectangle to subtract from.
 * @param subtraction The rectangle to subtract.
 */
CGRect CGRectDifference (CGRect rect, CGRect subtraction);
