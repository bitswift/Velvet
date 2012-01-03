//
//  NSView+VELBridgedViewAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Velvet/VELNSView.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSView+VELNSViewAdditions.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Proton/EXTSafeCategory.h>

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
    NSPoint superviewPoint = [self convertPoint:point toView:self.superview];
    id hitView = [self hitTest:superviewPoint];

    if ([hitView isKindOfClass:[NSVelvetView class]]) {
        NSPoint descendantPoint = [self convertPoint:point toView:hitView];
        return [hitView descendantViewAtPoint:descendantPoint];
    }

    return hitView;
}

- (BOOL)pointInside:(CGPoint)point {
    return [self hitTest:point] ? YES : NO;
}

@end
