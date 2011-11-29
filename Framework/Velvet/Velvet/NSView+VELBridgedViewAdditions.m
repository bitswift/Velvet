//
//  NSView+VELBridgedViewAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Velvet/VELNSView.h>
#import <Velvet/NSView+VELNSViewAdditions.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import "EXTSafeCategory.h"

@safecategory (NSView, VELBridgeViewAdditions)
- (CGPoint)convertFromWindowPoint:(CGPoint)point; {
    NSPoint windowPoint = NSPointFromCGPoint(point);
    NSPoint selfPoint = [self convertPoint:windowPoint fromView:nil];
    return NSPointToCGPoint(selfPoint);
}

- (CGPoint)convertToWindowPoint:(CGPoint)point; {
    NSPoint windowPoint = NSPointFromCGPoint(point);
    NSPoint selfPoint = [self convertPoint:windowPoint toView:nil];
    return NSPointToCGPoint(selfPoint);
}

- (CGRect)convertFromWindowRect:(CGRect)rect; {
    NSRect windowRect = NSRectFromCGRect(rect);
    NSRect selfRect = [self convertRect:windowRect fromView:nil];
    return NSRectToCGRect(selfRect);
}

- (CGRect)convertToWindowRect:(CGRect)rect; {
    NSRect windowRect = NSRectFromCGRect(rect);
    NSRect selfRect = [self convertRect:windowRect toView:nil];
    return NSRectToCGRect(selfRect);
}

- (id <VELBridgedView>)descendantViewAtPoint:(NSPoint)point {
    // convert point into our coordinate system, so it's ready to go for all
    // subviews (which expect it in their superview's coordinate system)
    point = [self convertPoint:point fromView:self.superview];

    __block id <VELBridgedView> result = (id <VELBridgedView>)self;

    // we need to avoid hitting any NSViews that are clipped by their
    // corresponding Velvet views
    [self.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSView <VELBridgedView> *view, NSUInteger index, BOOL *stop){
        VELNSView *hostView = view.hostView;
        if (hostView) {
            CGRect bounds = hostView.layer.bounds;
            CGRect clippedBounds = [hostView.layer convertAndClipRect:bounds toLayer:view.layer];

            CGPoint subviewPoint = [view convertPoint:point fromView:self];
            if (!CGRectContainsPoint(clippedBounds, subviewPoint)) {
                // skip this view
                return;
            }
        }

        id <VELBridgedView>hitTestedView = [view descendantViewAtPoint:point];
        if (hitTestedView) {
            result = hitTestedView;
            *stop = YES;
        }
    }];

    return result;
}
@end
