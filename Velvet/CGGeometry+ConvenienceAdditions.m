//
//  CGGeometry+ConvenienceAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/CGGeometry+ConvenienceAdditions.h>

CGRect CGRectChop (CGRect rect, CGFloat amount, CGRectEdge edge) {
    CGRect slice, remainder;
    CGRectDivide(rect, &slice, &remainder, amount, edge);

    return remainder;
}

CGRect CGRectGrow (CGRect rect, CGFloat amount, CGRectEdge edge) {
    switch (edge) {
        case CGRectMinXEdge:
            return CGRectMake(
                CGRectGetMinX(rect) - amount,
                CGRectGetMinY(rect),
                CGRectGetWidth(rect) + amount,
                CGRectGetHeight(rect)
            );

        case CGRectMinYEdge:
            return CGRectMake(
                CGRectGetMinX(rect),
                CGRectGetMinY(rect) - amount,
                CGRectGetWidth(rect),
                CGRectGetHeight(rect) + amount
            );

        case CGRectMaxXEdge:
            return CGRectMake(
                CGRectGetMinX(rect),
                CGRectGetMinY(rect),
                CGRectGetWidth(rect) + amount,
                CGRectGetHeight(rect)
            );

        case CGRectMaxYEdge:
            return CGRectMake(
                CGRectGetMinX(rect),
                CGRectGetMinY(rect),
                CGRectGetWidth(rect),
                CGRectGetHeight(rect) + amount
            );

        default:
            NSCAssert(NO, @"Unrecognized CGRectEdge %i", (int)edge);
            return CGRectNull;
    }
}

CGRect CGRectDifference (CGRect rect, CGRect subtraction) {
    if (CGRectEqualToRect(rect, subtraction))
        return CGRectZero;

    CGRect intersection = CGRectIntersection(rect, subtraction);
    if (CGRectIsNull(intersection))
        return rect;

    if (CGRectEqualToRect(intersection, rect)) {
        // the whole rectangle is contained in 'subtraction' (but not exactly
        // equal)
        return CGRectNull;
    }

    CGFloat minX = CGRectGetMinX(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat maxY = CGRectGetMaxY(rect);

    // don't chop width-wise if the whole rectangle intersects on that axis --
    // we already determined up above that the intersection won't cover our
    // whole rectangle, so we should only subtract along the other axis
    if (CGRectGetWidth(intersection) < CGRectGetWidth(rect)) {
        CGFloat iminX = CGRectGetMinX(intersection);
        CGFloat imaxX = CGRectGetMaxX(intersection);

        // if the intersection was mostly on our right side...
        if (iminX - minX >= maxX - imaxX) {
            // chop off the right side
            maxX = iminX;
        } else {
            // chop off the left side
            minX = imaxX;
        }
    }

    // don't chop height-wise if the whole rectangle intersects on that axis --
    // we already determined up above that the intersection won't cover our
    // whole rectangle, so we should only subtract along the other axis
    if (CGRectGetHeight(intersection) < CGRectGetHeight(rect)) {
        CGFloat iminY = CGRectGetMinY(intersection);
        CGFloat imaxY = CGRectGetMaxY(intersection);

        // if the intersection was mostly on our top side...
        if (iminY - minY >= maxY - imaxY) {
            // chop off the top side
            maxY = iminY;
        } else {
            // chop off the bottom side
            minY = imaxY;
        }
    }

    return CGRectMake(
        minX,
        minY,
        maxX - minX,
        maxY - minY
    );
}

