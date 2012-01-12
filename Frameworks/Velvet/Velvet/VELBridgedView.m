//
//  VELBridgedView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 12.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELBridgedView.h>
#import <Velvet/NSVelvetView.h>

@concreteprotocol(VELBridgedView)

#pragma mark Concrete methods

- (id<VELHostView>)hostView {
    id<VELHostView> hostView = objc_getAssociatedObject(self, @selector(hostView));
    if (hostView)
        return hostView;

    if ([self respondsToSelector:@selector(superview)]) {
        id superview = [(id)self superview];

        if ([superview respondsToSelector:@selector(hostView)])
            return [superview hostView];
    }

    return nil;
}

- (void)setHostView:(id<VELHostView>)hostView {
    objc_setAssociatedObject(self, @selector(hostView), hostView, OBJC_ASSOCIATION_ASSIGN);
}

- (NSVelvetView *)ancestorNSVelvetView; {
    id<VELHostView> hostView = self.hostView;

    if ([hostView isKindOfClass:[NSVelvetView class]])
        return (id)hostView;

    return hostView.ancestorNSVelvetView;
}

#pragma mark Unimplemented methods

- (CGPoint)convertFromWindowPoint:(CGPoint)point; {
    NSAssert(NO, @"%s must be overridden by conforming classes", __func__);
    return CGPointZero;
}

- (CGPoint)convertToWindowPoint:(CGPoint)point; {
    NSAssert(NO, @"%s must be overridden by conforming classes", __func__);
    return CGPointZero;
}

- (CGRect)convertFromWindowRect:(CGRect)rect; {
    NSAssert(NO, @"%s must be overridden by conforming classes", __func__);
    return CGRectZero;
}

- (CGRect)convertToWindowRect:(CGRect)rect; {
    NSAssert(NO, @"%s must be overridden by conforming classes", __func__);
    return CGRectZero;
}

- (CALayer *)layer; {
    NSAssert(NO, @"%s must be overridden by conforming classes", __func__);
    return nil;
}

- (id<VELBridgedView>)ancestorScrollView; {
    NSAssert(NO, @"%s must be overridden by conforming classes", __func__);
    return nil;
}

- (id<VELBridgedView>)descendantViewAtPoint:(CGPoint)point; {
    NSAssert(NO, @"%s must be overridden by conforming classes", __func__);
    return nil;
}

- (BOOL)pointInside:(CGPoint)point; {
    NSAssert(NO, @"%s must be overridden by conforming classes", __func__);
    return NO;
}

@end
