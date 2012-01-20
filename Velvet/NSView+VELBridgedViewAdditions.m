//
//  NSView+VELBridgedViewAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "NSView+VELBridgedViewAdditions.h"
#import "NSVelvetView.h"
#import <objc/runtime.h>
#import "EXTSafeCategory.h"

@safecategory (NSView, VELBridgedViewAdditions)

#pragma mark Category loading

+ (void)load {
    class_addProtocol([NSView class], @protocol(VELBridgedView));
}

#pragma mark View hierarchy

- (id<VELHostView>)hostView {
    id<VELHostView> hostView = objc_getAssociatedObject(self, @selector(hostView));
    if (hostView)
        return hostView;
    else
        return self.superview.hostView;
}

- (void)setHostView:(id<VELHostView>)hostView {
    objc_setAssociatedObject(self, @selector(hostView), hostView, OBJC_ASSOCIATION_ASSIGN);
}

- (void)ancestorDidLayout; {
    [self.subviews makeObjectsPerformSelector:_cmd];
}

- (NSVelvetView *)ancestorNSVelvetView; {
    NSView *view = self;

    do {
        if ([view isKindOfClass:[NSVelvetView class]])
            return (id)view;

        view = view.superview;
    } while (view);
    
    return nil;
}

- (id<VELBridgedView>)ancestorScrollView {
    if ([self isKindOfClass:[NSScrollView class]])
        return self;

    id<VELHostView> immediateHostView = objc_getAssociatedObject(self, @selector(hostView));
    if (immediateHostView)
        return immediateHostView.ancestorScrollView;

    return self.superview.ancestorScrollView;
}

#pragma mark Geometry

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

#pragma mark Hit testing

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

#pragma mark View hierarchy

- (void)willMoveToNSVelvetView:(NSVelvetView *)view; {
    [self.subviews makeObjectsPerformSelector:_cmd withObject:view];
}

- (void)didMoveFromNSVelvetView:(NSVelvetView *)view; {
    [self.subviews makeObjectsPerformSelector:_cmd withObject:view];
}

@end
