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

- (id<VELBridgedView>)descendantViewAtPoint:(NSPoint)point {
    // Clip to self
    if (!CGRectContainsPoint(self.bounds, point))
        return nil;

    __block id<VELBridgedView> result = (id<VELBridgedView>)self;

    [self.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSView <VELBridgedView> *view, NSUInteger index, BOOL *stop){

        CGPoint subviewPoint = [view convertPoint:point fromView:self];

        id<VELBridgedView>hitTestedView = [view descendantViewAtPoint:subviewPoint];
        if (hitTestedView) {
            result = hitTestedView;
            *stop = YES;
        }
    }];

    return result;
}
@end
