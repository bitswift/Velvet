//
//  NSViewClipRenderer.m
//  Velvet
//
//  Created by Josh Vera on 11/26/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSViewClipRenderer.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/NSView+VELGeometryAdditions.h>
#import <Velvet/VELNSView.h>
#import <QuartzCore/QuartzCore.h>

@implementation NSViewClipRenderer

#pragma mark Properties
@synthesize originalLayerDelegate = m_originalLayerDelegate;
@synthesize clippedView = m_clippedView;

#pragma mark Forwarding

- (id)forwardingTargetForSelector:(SEL)selector {
    return self.originalLayerDelegate;
}

- (BOOL)respondsToSelector:(SEL)selector {
    if (selector != @selector(drawLayer:inContext:) && [[self class] instancesRespondToSelector:selector]) {
        return YES;
    }

    return [self.originalLayerDelegate respondsToSelector:selector];
}

#pragma mark CALayer delegate

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    CGRect selfBounds = self.clippedView.layer.bounds;
    CGRect viewBounds = [self.clippedView.layer convertAndClipRect:selfBounds toLayer:self.clippedView.NSView.layer];

    CGContextSaveGState(context);
    CGContextClipToRect(context, viewBounds);
    [self.originalLayerDelegate drawLayer:layer inContext:context];
    CGContextRestoreGState(context);
}

@end
