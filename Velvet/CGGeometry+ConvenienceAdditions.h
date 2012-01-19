//
//  CGGeometry+ConvenienceAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
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

/**
 * Adds the given amount to a rectangle's edge.
 *
 * @param rect The rectangle to grow.
 * @param amount The amount of points to add.
 * @param edge The edge from which to grow. Growing is always outward (i.e.,
 * using `CGRectMaxXEdge` will increase the width of the rectangle and leave the
 * origin unmodified).
 */
CGRect CGRectGrow (CGRect rect, CGFloat amount, CGRectEdge edge);

/**
 * Divides a source rectangle into two component rectangles, determined by
 * "cutting out" a region that intersects with another rectangle.
 *
 * This function will do the following:
 *
 *  1. Determine the intersection of `rect` and `intersectingRect`.
 *  2. If `rect` does not intersect `intersectingRect`, set `slice` to `rect`,
 *  set `remainder` to `CGRectNull`, and return immediately.
 *  3. _Starting from_ the given edge, cut `rect` until the start of the
 *  intersection is reached. If the intersection starts outside of `rect`, set
 *  `slice` to `CGRectNull`; otherwise, set `slice` to the cut region (which may
 *  be of zero size along the cutting axis).
 *  4. Starting from the given edge, skip the entire length of the intersection.
 *  5. If the intersection ends outside of `rect`, set `remainder` to
 *  `CGRectNull`; otherwise, set `remainder` to whatever region of `rect`
 *  remains (which may be of zero size along the cutting axis).
 *
 * @param rect The rectangle to divide.
 * @param slice Upon return, the portion of `rect` starting from `edge` and
 * continuing until the intersection of `rect` and `intersectingRect`. This
 * argument may be `NULL` to not return the slice.
 * @param remainder Upon return, the portion of `rect` starting _after_ the
 * intersection of `rect` and `intersectingRect`, and continuing until the end
 * of `rect`. This argument may be `NULL` to not return the remainder.
 * @param intersectingRect A rectangle to intersect with `rect` in order to
 * determine where and how much to cut.
 * @param edge The edge from which cutting begins, with cutting proceeding
 * toward the opposite edge.
 */
void CGRectDivideExcludingIntersection (CGRect rect, CGRect *slice, CGRect *remainder, CGRect intersectingRect, CGRectEdge edge);
