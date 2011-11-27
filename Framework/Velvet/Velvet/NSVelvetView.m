//
//  NSVelvetView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSVelvetView.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/NSVelvetHostView.h>
#import <Velvet/NSView+VELNSViewAdditions.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELNSView.h>
#import <Velvet/VELView.h>
#import <Velvet/VELViewPrivate.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface NSVelvetView ()
@property (nonatomic, strong) NSView *velvetHostView;
@property (nonatomic, readwrite, strong) VELContext *context;

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

    // enable layer-backing for this view (as high as possible in the view
    // hierarchy, to keep as much as possible in CA)
    [self setWantsLayer:YES];

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
    // convert point into our coordinate system, so it's ready to go for all
    // subviews (which expect it in their superview's coordinate system)
    point = [self convertPoint:point fromView:self.superview];

    // we need to avoid hitting any NSViews that are clipped by their
    // corresponding Velvet views
    for (NSView *view in self.subviews) {
        VELNSView *hostView = view.hostView;
        if (hostView) {
            CGRect bounds = hostView.layer.bounds;
            CGRect clippedBounds = [hostView.layer convertAndClipRect:bounds toLayer:view.layer];

            CGPoint subviewPoint = [view convertPoint:point fromView:self];
            if (!CGRectContainsPoint(clippedBounds, subviewPoint))
                continue;
        }

        NSView *hitTestedView = [view hitTest:point];
        if (hitTestedView)
            return hitTestedView;
    }

    return self;
}

@end
