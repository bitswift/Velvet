//
//  AppKit+GeometryAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 06.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "AppKit+GeometryAdditions.h"

BOOL NSEqualEdgeInsets (NSEdgeInsets a, NSEdgeInsets b) {
    const CGFloat tolerance = 0.001;

    if (fabs(a.left - b.left) > tolerance)
        return NO;

    if (fabs(a.top - b.top) > tolerance)
        return NO;

    if (fabs(a.right - b.right) > tolerance)
        return NO;

    if (fabs(a.bottom - b.bottom) > tolerance)
        return NO;

    return YES;
}
