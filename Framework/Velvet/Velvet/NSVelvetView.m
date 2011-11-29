//
//  NSVelvetView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSVelvetView.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/NSVelvetHostView.h>
#import <Velvet/NSView+VELNSViewAdditions.h>
#import <Velvet/NSViewClipRenderer.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELFocusRingLayer.h>
#import <Velvet/VELNSView.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/VELView.h>
#import <Velvet/VELViewPrivate.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static NSComparisonResult compareNSViewOrdering (NSView *viewA, NSView *viewB, void *context) {
    VELView *velvetA = viewA.hostView;
    VELView *velvetB = viewB.hostView;

    // Velvet-hosted NSViews should be on top of everything else
    if (!velvetA) {
        if (!velvetB) {
            return NSOrderedSame;
        } else {
            return NSOrderedAscending;
        }
    } else if (!velvetB) {
        return NSOrderedDescending;
    }

    VELView *ancestor = [velvetA ancestorSharedWithView:velvetB];
    NSCAssert2(ancestor, @"Velvet-hosted NSViews in the same NSVelvetView should share a Velvet ancestor: %@, %@", viewA, viewB);

    __block NSInteger orderA = -1;
    __block NSInteger orderB = -1;

    [ancestor.subviews enumerateObjectsUsingBlock:^(VELView *subview, NSUInteger index, BOOL *stop){
        if ([velvetA isDescendantOfView:subview]) {
            orderA = (NSInteger)index;
        } else if ([velvetB isDescendantOfView:subview]) {
            orderB = (NSInteger)index;
        }

        if (orderA >= 0 && orderB >= 0) {
            *stop = YES;
        }
    }];

    if (orderA < orderB) {
        return NSOrderedAscending;
    } else if (orderA > orderB) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

@interface NSVelvetView ()
@property (nonatomic, strong) NSView *velvetHostView;
@property (nonatomic, readwrite, strong) VELContext *context;
@property (nonatomic, assign, getter = isUserInteractionEnabled) BOOL userInteractionEnabled;

/*
 * Configures all the necessary properties on the receiver. This is outside of
 * an initializer because \c NSView has no true designated initializer.
 */
- (void)setUp;
@end

@implementation NSVelvetView

#pragma mark Properties

@synthesize context = m_context;
@synthesize rootView = m_rootView;
@synthesize velvetHostView = m_velvetHostView;
@synthesize userInteractionEnabled = m_userInteractionEnabled;

- (void)setRootView:(VELView *)view; {
    // disable implicit animations, or the layers will fade in and out
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    [m_rootView.layer removeFromSuperlayer];
    [self.velvetHostView.layer addSublayer:view.layer];

    m_rootView.hostView = nil;
    view.hostView = self;

    m_rootView = view;

    [CATransaction commit];
}

#pragma mark Lifecycle

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self)
        return nil;

    [self setUp];
    return self;
}

- (id)initWithFrame:(NSRect)frame; {
    self = [super initWithFrame:frame];
    if (!self)
        return nil;

    [self setUp];
    return self;
}

- (void)setUp; {
    self.context = [[VELContext alloc] init];
    self.userInteractionEnabled = YES;

    // enable layer-backing for this view
    [self setWantsLayer:YES];
    self.layer.layoutManager = self;

    self.velvetHostView = [[NSVelvetHostView alloc] initWithFrame:self.bounds];
    self.velvetHostView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:self.velvetHostView];

    self.rootView = [[VELView alloc] init];
    self.rootView.frame = self.bounds;
}

#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize; {
    // always resize the root view to fill this view
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.rootView.layer.frame = self.velvetHostView.layer.frame = self.bounds;
    [CATransaction commit];
}

#pragma mark Event handling

- (NSView *)hitTest:(NSPoint)point {
    if (!self.userInteractionEnabled)
        return nil;

    // convert point into our coordinate system, so it's ready to go for all
    // subviews (which expect it in their superview's coordinate system)
    point = [self convertPoint:point fromView:self.superview];

    __block NSView *result = self;

    // we need to avoid hitting any NSViews that are clipped by their
    // corresponding Velvet views
    [self.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSView *view, NSUInteger index, BOOL *stop){
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

        NSView *hitTestedView = [view hitTest:point];
        if (hitTestedView) {
            result = hitTestedView;
            *stop = YES;
        }
    }];

    return result;
}

#pragma mark NSView hierarchy

- (void)didAddSubview:(NSView *)subview {
    [self sortSubviewsUsingFunction:&compareNSViewOrdering context:NULL];
}

#pragma mark CALayer delegate

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    if ([[NSVelvetView superclass] instancesRespondToSelector:_cmd]) {
        [super performSelector:@selector(layoutSublayersOfLayer:) withObject:layer];
    }

    NSArray *existingSublayers = [layer.sublayers copy];

    [CATransaction performWithDisabledActions:^{
        for (CALayer *sublayer in existingSublayers) {
            if (!sublayer.delegate && sublayer != self.velvetHostView.layer) {
                // this is probably a focus ring -- try to find the view that it
                // belongs to so we can clip it
                for (NSView *view in self.subviews) {
                    if (!CGRectContainsRect(sublayer.frame, view.frame))
                        continue;

                    VELNSView *hostView = view.hostView;
                    if (!hostView || !hostView.superview) {
                        // don't need to clip if there's no superview of this VELNSView
                        continue;
                    }

                    VELFocusRingLayer *focusRingLayer = [[VELFocusRingLayer alloc] initWithOriginalLayer:sublayer hostView:hostView];
                    [self.layer addSublayer:focusRingLayer];

                    focusRingLayer.frame = sublayer.frame; 
                    hostView.focusRingLayer = focusRingLayer;

                    break;
                }
            }
        } 
    }];
}

@end
