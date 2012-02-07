//
//  CGGeometry+ConvenienceAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "CGGeometry+ConvenienceAdditions.h"

CGPoint CGRectCenterPoint (CGRect rect) {
    return CGPointMake(
        CGRectGetMinX(rect) + CGRectGetWidth(rect) / 2,
        CGRectGetMinY(rect) + CGRectGetHeight(rect) / 2
    );
}

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

void CGRectDivideExcludingIntersection (CGRect rect, CGRect *slice, CGRect *remainder, CGRect intersectingRect, CGRectEdge edge) {
    if (!CGRectIntersectsRect(rect, intersectingRect)) {
        // always set these exact arguments, regardless of edge, since those are
        // the semantics we defined in the interface

        if (slice)
            *slice = rect;

        if (remainder)
            *remainder = CGRectNull;

        return;
    }

    /*
     * This function is symmetric, so we'll calculate everything using MinX/MinY
     * logic, and then simply swap our output values before returning.
     */

    // updated in the switch statement down below
    BOOL wasMinEdge = (edge == CGRectMinXEdge || edge == CGRectMinYEdge);

    void (^setSlice)(CGRect) = ^(CGRect rect){
        if (wasMinEdge) {
            if (slice)
                *slice = rect;
        } else {
            if (remainder)
                *remainder = rect;
        }
    };

    void (^setRemainder)(CGRect) = ^(CGRect rect){
        if (wasMinEdge) {
            if (remainder)
                *remainder = rect;
        } else {
            if (slice)
                *slice = rect;
        }
    };

    // distance from the start of rect to the start of the intersectingRect (may be
    // negative)
    CGFloat rectStartTointersectingRectStart;

    // distance from the end of the intersectingRect to the end of the rect (may be
    // negative)
    CGFloat intersectingRectEndToRectEnd;

    // length of the intersection along the cutting axis
    CGFloat intersectionLength;

    switch (edge) {
        case CGRectMaxXEdge:
            edge = CGRectMinXEdge;

            // fall through

        case CGRectMinXEdge:
            rectStartTointersectingRectStart = CGRectGetMinX(intersectingRect) - CGRectGetMinX(rect);
            intersectingRectEndToRectEnd = CGRectGetMaxX(rect) - CGRectGetMaxX(intersectingRect);
            intersectionLength = fmin(CGRectGetWidth(intersectingRect), CGRectGetWidth(rect));
            break;

        case CGRectMaxYEdge:
            edge = CGRectMinYEdge;

            // fall through

        case CGRectMinYEdge:
            rectStartTointersectingRectStart = CGRectGetMinY(intersectingRect) - CGRectGetMinY(rect);
            intersectingRectEndToRectEnd = CGRectGetMaxY(rect) - CGRectGetMaxY(intersectingRect);
            intersectionLength = fmin(CGRectGetHeight(intersectingRect), CGRectGetHeight(rect));
            break;

        default:
            NSCAssert(NO, @"Unrecognized CGRectEdge %i", (int)edge);
    }

    CGRect totalRemainder = rect;

    if (rectStartTointersectingRectStart < 0) {
        setSlice(CGRectNull);
    } else {
        CGRect slice;
        CGRectDivide(totalRemainder, &slice, &totalRemainder, rectStartTointersectingRectStart, edge);

        setSlice(slice);
    }

    if (intersectionLength) {
        CGRect unusedSlice;
        CGRectDivide(totalRemainder, &unusedSlice, &totalRemainder, intersectionLength, edge);
    }

    if (intersectingRectEndToRectEnd < 0) {
        setRemainder(CGRectNull);
    } else {
        CGRect remainder;
        CGRectDivide(totalRemainder, &remainder, &totalRemainder, intersectingRectEndToRectEnd, edge);

        setRemainder(remainder);
    }
}

void CGRectDivideWithPadding (CGRect rect, CGRect *slicePtr, CGRect *remainderPtr, CGFloat sliceAmount, CGFloat padding, CGRectEdge edge) {
    CGRect slice;

    // slice
    CGRectDivide(rect, &slice, &rect, sliceAmount, edge);
    if (slicePtr)
        *slicePtr = slice;

    // padding / remainder
    CGRectDivide(rect, &slice, &rect, padding, edge);
    if (remainderPtr)
        *remainderPtr = rect;
}

CGRect CGRectFloor(CGRect rect) {
    return CGRectMake(
        floor(rect.origin.x),
        ceil(rect.origin.y),
        floor(rect.size.width),
        floor(rect.size.height)
    );
}

CGRect CGRectMakeInverted (CGRect containingRect, CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    return CGRectMake(
        x,
        CGRectGetHeight(containingRect) - y - height,
        width,
        height
    );
}

BOOL CGRectEqualToRectWithAccuracy (CGRect rect, CGRect rect2, CGFloat epsilon) {
    if (!CGPointEqualToPointWithAccuracy(rect.origin, rect2.origin, epsilon))
        return NO;

    if (!CGSizeEqualToSizeWithAccuracy(rect.size, rect2.size, epsilon))
        return NO;

    return YES;
}

CGRect CGRectWithSize (CGSize size) {
    return CGRectMake(0, 0, size.width, size.height);
}

BOOL CGSizeEqualToSizeWithAccuracy (CGSize size, CGSize size2, CGFloat epsilon) {
    return (fabs(size.width - size2.width) <= epsilon) && (fabs(size.height - size2.height) <= epsilon);
}

CGPoint CGPointFloor(CGPoint point) {
    return CGPointMake(floor(point.x), ceil(point.y));
}

BOOL CGPointEqualToPointWithAccuracy(CGPoint p, CGPoint q, CGFloat epsilon) {
    return (fabs(p.x - q.x) <= epsilon) && (fabs(p.y - q.y) <= epsilon);
}

CGFloat CGPointDotProduct(CGPoint point, CGPoint point2) {
    return (point.x * point2.x + point.y * point2.y);
}

CGPoint CGPointScale(CGPoint point, CGFloat scale) {
    return CGPointMake(point.x * scale, point.y * scale);
}

CGFloat CGPointLength(CGPoint point) {
    return (CGFloat)sqrt(CGPointDotProduct(point, point));
}

CGPoint CGPointNormalize(CGPoint point) {
    CGFloat len = CGPointLength(point);
    if (len > 0)
        return CGPointScale(point, 1/len);

    return point;
}

CGPoint CGPointProject(CGPoint point, CGPoint direction) {
    CGPoint normalizedDirection = CGPointNormalize(direction);
    CGFloat distance = CGPointDotProduct(point, normalizedDirection);

    return CGPointScale(normalizedDirection, distance);
}

CGPoint CGPointProjectAlongAngle(CGPoint point, CGFloat angleInDegrees) {
    CGFloat angleInRads = angleInDegrees * M_PI / 180;
    CGPoint direction = CGPointMake(cos(angleInRads), sin(angleInRads));
    return CGPointProject(point, direction);
}

CGFloat CGPointAngleInDegrees(CGPoint point) {
    return atan2(point.y, point.x) * 180 / M_PI;
}

CGPoint CGPointAdd(CGPoint p1, CGPoint p2) {
    return CGPointMake(p1.x + p2.x, p1.y + p2.y);
}

CGPoint CGPointSubtract(CGPoint p1, CGPoint p2) {
    return CGPointMake(p1.x - p2.x, p1.y - p2.y);
}
