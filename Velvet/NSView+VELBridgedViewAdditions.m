//
//  NSView+VELBridgedViewAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "NSView+VELBridgedViewAdditions.h"
#import "EXTSafeCategory.h"
#import "NSVelvetView.h"
#import "VELScrollView.h"
#import <objc/runtime.h>

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

- (id<VELBridgedView>)immediateParentView {
    id<VELHostView> hostView = objc_getAssociatedObject(self, @selector(hostView));
    if (hostView)
        return hostView;
    else
        return self.superview;
}

- (void)setHostView:(id<VELHostView>)hostView {
    objc_setAssociatedObject(self, @selector(hostView), hostView, OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)isFocused {
    return [objc_getAssociatedObject(self, @selector(isFocused)) boolValue];
}

- (void)setFocused:(BOOL)focused {
    objc_setAssociatedObject(self, @selector(isFocused), [NSNumber numberWithBool:focused], OBJC_ASSOCIATION_COPY_NONATOMIC);

    for (NSView *view in self.subviews) {
        self.focused = focused;
    }
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

- (id<VELScrollView>)ancestorScrollView {
    if ([self conformsToProtocol:@protocol(VELScrollView)])
        return (id)self;

    return self.immediateParentView.ancestorScrollView;
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
    NSPoint superviewPoint = [self convertPoint:point toView:self.superview];
    return [self hitTest:superviewPoint] ? YES : NO;
}

#pragma mark View hierarchy

- (void)willMoveToNSVelvetView:(NSVelvetView *)view; {
    [self.subviews makeObjectsPerformSelector:_cmd withObject:view];
}

- (void)didMoveFromNSVelvetView:(NSVelvetView *)view; {
    [self.subviews makeObjectsPerformSelector:_cmd withObject:view];
}

- (void)viewHierarchyDidChange {
    [self.subviews makeObjectsPerformSelector:_cmd];
}

@end
