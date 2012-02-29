//
//  NSClipView+VELScrollViewAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.02.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSClipView+VELScrollViewAdditions.h"
#import "EXTSafeCategory.h"
#import <objc/runtime.h>

@safecategory (NSClipView, VELScrollViewAdditions)

#pragma mark Category initialization

+ (void)load {
    class_addProtocol([NSClipView class], @protocol(VELScrollView));
}

#pragma mark VELScrollView

- (void)scrollToIncludeRect:(CGRect)rect; {
    CGRect visibleRect = self.documentVisibleRect;
    CGSize visibleSize = visibleRect.size;

    CGPoint newScrollPoint = visibleRect.origin;

    if (CGRectGetMinX(rect) < CGRectGetMinX(visibleRect)) {
        newScrollPoint.x = CGRectGetMinX(rect);
    } else if (CGRectGetMaxX(rect) > CGRectGetMaxX(visibleRect)) {
        newScrollPoint.x = fmax(0, CGRectGetMaxX(rect) - visibleSize.width);
    }

    if (CGRectGetMinY(rect) < CGRectGetMinY(visibleRect)) {
        newScrollPoint.y = CGRectGetMinY(rect);
    } else if (CGRectGetMaxY(rect) > CGRectGetMaxY(visibleRect)) {
        newScrollPoint.y = fmax(0, CGRectGetMaxY(rect) - visibleSize.width);
    }

    [self scrollToPoint:newScrollPoint];
}

@end
