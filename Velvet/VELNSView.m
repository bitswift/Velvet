//
//  VELNSView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELNSView.h"
#import <QuartzCore/QuartzCore.h>
#import "CATransaction+BlockAdditions.h"
#import "CGBitmapContext+PixelFormatAdditions.h"
#import "NSColor+CoreGraphicsAdditions.h"
#import "NSVelvetView.h"
#import "NSVelvetViewPrivate.h"
#import "NSView+VELBridgedViewAdditions.h"
#import "VELNSViewLayerDelegateProxy.h"
#import "VELNSViewPrivate.h"
#import "EXTScope.h"

@interface VELNSView () {
    /**
     * A count indicating how many nested calls to <startRenderingContainedView>
     * are in effect.
     */
    NSUInteger m_renderingContainedViewCount;

    #ifdef DEBUG
    /**
     * An observer for `VELHostViewDebugModeChangedNotification`.
     */
    id m_hostViewDebugModeObserver;
    #endif
}

- (void)synchronizeNSViewGeometry;
- (void)startRenderingContainedView;
- (void)stopRenderingContainedView;

/*
 * An object for proxying the layer delegate of the `NSView` (typically the
 * `NSView` itself), used to disable implicit animations.
 */
@property (nonatomic, strong) VELNSViewLayerDelegateProxy *layerDelegateProxy;
@end

@implementation VELNSView

#pragma mark Properties

@synthesize guestView = m_guestView;
@synthesize layerDelegateProxy = m_layerDelegateProxy;

- (void)setGuestView:(NSView *)view {
    NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

    // remove any existing guest view
    [m_guestView removeFromSuperview];
    m_guestView.hostView = nil;

    m_guestView = view;

    NSVelvetView *velvetView = self.ancestorNSVelvetView;

    // and set up our new view
    if (m_guestView) {
        // set up layer-backing on the view
        [m_guestView setWantsLayer:YES];
        [m_guestView setNeedsDisplay:YES];

        self.layerDelegateProxy = [VELNSViewLayerDelegateProxy layerDelegateProxyWithLayer:m_guestView.layer];

        [velvetView.appKitHostView addSubview:m_guestView];
        m_guestView.hostView = self;

        [velvetView recalculateNSViewOrdering];

        m_guestView.nextResponder = self;
        [self synchronizeNSViewGeometry];
    } else {
        self.layerDelegateProxy = nil;

        // remove the old view from the NSVelvetView's clipping path
        [velvetView recalculateNSViewClipping];
    }
}

- (CGRect)NSViewFrame; {
    // we use 'self' and 'bounds' here instead of the superview and frame
    // because the superview may be a VELScrollView, and accessing it directly
    // will skip over the CAScrollLayer that's in the hierarchy
    return [self convertRect:self.bounds toView:self.ancestorNSVelvetView.guestView];
}

- (void)setCenter:(CGPoint)center {
    [super setCenter:center];
    [self synchronizeNSViewGeometry];
}

- (void)setSubviews:(NSArray *)subviews {
    NSAssert2(![subviews count], @"%@ must be a leaf in the Velvet hierarchy, cannot add subviews: %@", self, subviews);

    // if assertions are disabled, proceed anyways (better to glitch out than
    // crash)
    [super setSubviews:subviews];
}

- (BOOL)isRenderingContainedView {
    return m_renderingContainedViewCount > 0;
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.layer.masksToBounds = NO;

    // prevents the layer from displaying until we need to render our contained
    // view
    self.contentMode = VELViewContentModeScaleToFill;
    return self;
}

- (id)initWithNSView:(NSView *)view; {
    NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

    self = [self init];
    if (!self)
        return nil;

    self.guestView = view;
    self.frame = view.frame;
    return self;
}

- (void)dealloc {
    #ifdef DEBUG
    if (m_hostViewDebugModeObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:m_hostViewDebugModeObserver];
        m_hostViewDebugModeObserver = nil;
    }
    #endif

    self.guestView.hostView = nil;
}

#pragma mark Geometry

- (void)synchronizeNSViewGeometry; {
    NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

    if (!self.window) {
        // can't do this without being in a window
        return;
    }

    NSAssert(self.ancestorNSVelvetView, @"%@ should be in an NSVelvetView if it has a window", self);

    CGRect frame = self.NSViewFrame;
    self.guestView.frame = frame;

    [self.ancestorNSVelvetView recalculateNSViewClipping];
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
    if (!self.renderingContainedView) {
        return;
    }

    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
    [self.guestView.layer renderInContext:context];
}

- (void)startRenderingContainedView; {
    if (m_renderingContainedViewCount++ == 0) {
        [CATransaction performWithDisabledActions:^{
            [self.layer setNeedsDisplay];
            [self.layer displayIfNeeded];
        }];
    }
}

- (void)stopRenderingContainedView; {
    NSAssert(m_renderingContainedViewCount > 0, @"Mismatched call to %s", __func__);

    if (--m_renderingContainedViewCount == 0) {
        self.layer.contents = nil;
    }
}

#pragma mark View hierarchy

- (void)ancestorDidLayout; {
    [self synchronizeNSViewGeometry];
    [super ancestorDidLayout];
}

- (void)willMoveToNSVelvetView:(NSVelvetView *)view; {
    [super willMoveToNSVelvetView:view];
    [self.guestView willMoveToNSVelvetView:view];

    [CATransaction performWithDisabledActions:^{
        [self.guestView removeFromSuperview];
    }];
}

- (void)didMoveFromNSVelvetView:(NSVelvetView *)view; {
    [super didMoveFromNSVelvetView:view];

    @onExit {
        [self.guestView didMoveFromNSVelvetView:view];
    };

    NSVelvetView *newView = self.ancestorNSVelvetView;
    if (!newView) {
        return;
    }

    [CATransaction performWithDisabledActions:^{
        [newView.appKitHostView addSubview:self.guestView];
    }];

    self.guestView.nextResponder = self;
}

- (void)viewHierarchyDidChange {
    [super viewHierarchyDidChange];

    @onExit {
        [self.guestView viewHierarchyDidChange];
    };

    // verify that VELNSViews are on top of other subviews
    #if DEBUG
    NSArray *siblings = self.superview.subviews;
    __block BOOL foundVelvetView = NO;

    [siblings enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(VELView *view, NSUInteger index, BOOL *stop){
        if ([view isKindOfClass:[VELNSView class]]) {
            NSAssert2(!foundVelvetView, @"%@ must be on top of its sibling VELViews: %@", view, siblings);
        } else {
            foundVelvetView = YES;
        }
    }];
    #endif

    [self.ancestorNSVelvetView recalculateNSViewOrdering];
    [self synchronizeNSViewGeometry];
}

- (id<VELBridgedView>)descendantViewAtPoint:(CGPoint)point {
    if (![self pointInside:point])
        return nil;

    CGPoint NSViewPoint = [self.guestView convertFromWindowPoint:[self convertToWindowPoint:point]];

    // never return 'self', since we don't want to catch clicks that didn't
    // directly hit the NSView
    return [self.guestView descendantViewAtPoint:NSViewPoint];
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [self synchronizeNSViewGeometry];
}

- (CGSize)sizeThatFits:(CGSize)constraint {
    NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

    id view = self.guestView;
    NSSize cellSize = NSMakeSize(10000, 10000);

    NSCell *cell = nil;

    if ([view respondsToSelector:@selector(cell)]) {
        cell = [view cell];
    }

    if ([cell respondsToSelector:@selector(cellSize)]) {
        cellSize = [cell cellSize];
    }

    // if we don't have a cell, or it didn't give us a true size
    if (CGSizeEqualToSize(cellSize, CGSizeMake(10000, 10000))) {
        return [super sizeThatFits:constraint];
    }

    return cellSize;
}

#pragma mark NSObject overrides

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> frame = %@, NSView = %@ %@", [self class], self, NSStringFromRect(self.frame), self.guestView, NSStringFromRect(self.guestView.frame)];
}

@end
