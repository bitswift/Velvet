//
//  CGGeometry+ConvenienceAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

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
