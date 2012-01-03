//
//  VELNSView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELNSView.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/CGBitmapContext+PixelFormatAdditions.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSView+VELNSViewAdditions.h>
#import <Velvet/NSViewClipRenderer.h>
#import <Velvet/VELFocusRingLayer.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/VELViewProtected.h>
#import <QuartzCore/QuartzCore.h>

@interface VELNSView ()
/*
 * Documented in <VELNSViewPrivate>.
 */
@property (nonatomic, assign) BOOL rendersContainedView;

/*
 * Documented in <VELNSViewPrivate>.
 */
@property (nonatomic, strong) VELFocusRingLayer *focusRingLayer;

/*
 * The delegate for the layer of the contained <NSView>. This object is
 * responsible for rendering it while taking into account any clipping paths.
 */
@property (nonatomic, strong) NSViewClipRenderer *clipRenderer;

- (void)synchronizeNSViewGeometry;
@end

@implementation VELNSView

#pragma mark Properties

@synthesize NSView = m_NSView;
@synthesize clipRenderer = m_clipRenderer;
@synthesize rendersContainedView = m_rendersContainedView;
@synthesize focusRingLayer = m_focusRingLayer;

- (void)setNSView:(NSView *)view {
    NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

    // remove any existing NSView
    [m_NSView removeFromSuperview];
    m_NSView.hostView = nil;

    self.focusRingLayer = nil;
    self.clipRenderer = nil;

    m_NSView = view;

    // and set up our new view
    if (m_NSView) {
        // set up layer-backing on the view
        [m_NSView setWantsLayer:YES];
        [m_NSView setNeedsDisplay:YES];

        [self.hostView addSubview:m_NSView];
        m_NSView.hostView = self;

        m_NSView.nextResponder = self;

        self.clipRenderer = [[NSViewClipRenderer alloc] initWithClippedView:self layer:view.layer];
    }
}

- (CGRect)NSViewFrame; {
    // we use 'self' and 'bounds' here instead of the superview and frame
    // because the superview may be a VELScrollView, and accessing it directly
    // will skip over the CAScrollLayer that's in the hierarchy
    return [self convertRect:self.bounds toView:self.hostView.rootView];
}

- (void)setSubviews:(NSArray *)subviews {
    NSAssert2(![subviews count], @"%@ must be a leaf in the Velvet hierarchy, cannot add subviews: %@", self, subviews);

    // if assertions are disabled, proceed anyways (better to glitch out than
    // crash)
    [super setSubviews:subviews];
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.layer.masksToBounds = NO;
    return self;
}

- (id)initWithNSView:(NSView *)view; {
    NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

    self = [self init];
    if (!self)
        return nil;

    self.NSView = view;
    self.frame = view.frame;
    return self;
}

- (void)dealloc {
    self.NSView.hostView = nil;
}

#pragma mark Geometry

- (void)synchronizeNSViewGeometry; {
    NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

    if (!self.window) {
        // can't do this without being in a window
        return;
    }

    NSAssert(self.hostView, @"%@ should have a hostView if it has a window", self);

    CGRect frame = self.NSViewFrame;
    self.NSView.frame = frame;

    [CATransaction performWithDisabledActions:^{
        self.focusRingLayer.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
        [self.focusRingLayer setNeedsDisplay];
        [self.focusRingLayer displayIfNeeded];
    }];

    // if the frame has changed, we'll need to go through our clipRenderer's
    // -drawLayer:inContext: logic again with the new location and size
    [self.clipRenderer clip];
}

#pragma mark View hierarchy

- (void)ancestorDidLayout; {
    [self synchronizeNSViewGeometry];
    [super ancestorDidLayout];
}

- (void)willMoveToHostView:(NSVelvetView *)hostView {
    [super willMoveToHostView:hostView];
    [self.NSView removeFromSuperview];
    [self.focusRingLayer removeFromSuperlayer];
    self.focusRingLayer = nil;
}

- (void)didMoveFromHostView:(NSVelvetView *)oldHostView {
    [super didMoveFromHostView:oldHostView];

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

    // this must only be added after we've completely moved to the host view,
    // because it'll do some ancestor checks for NSView ordering
    [self.hostView addSubview:self.NSView];
    [self synchronizeNSViewGeometry];

    self.NSView.nextResponder = self;
}

- (id<VELBridgedView>)descendantViewAtPoint:(CGPoint)point {
    if (!CGRectContainsPoint(self.bounds, point))
        return nil;


    CGPoint NSViewPoint = [self.NSView convertFromWindowPoint:[self convertToWindowPoint:point]];
    return [self.NSView descendantViewAtPoint:NSViewPoint] ?: [super descendantViewAtPoint:point];
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [self synchronizeNSViewGeometry];
}

- (CGSize)sizeThatFits:(CGSize)constraint {
    NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

    id view = self.NSView;
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
    return [NSString stringWithFormat:@"<%@ %p> frame = %@, NSView = %@ %@", [self class], self, NSStringFromRect(self.frame), self.NSView, NSStringFromRect(self.NSView.frame)];
}

#pragma mark CALayer delegate

- (void)renderContainedViewInLayer:(CALayer *)layer {
    CGContextRef context = CGBitmapContextCreateGeneric(self.bounds.size, YES);

    [self.NSView.layer renderInContext:context];

    CGImageRef image = CGBitmapContextCreateImage(context);
    layer.contents = (__bridge_transfer id)image;

    CGContextRelease(context);
}

- (void)setRendersContainedView:(BOOL)rendersContainedView {
    NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

    if (m_rendersContainedView != rendersContainedView) {
        m_rendersContainedView = rendersContainedView;
        if (rendersContainedView) {
            [CATransaction performWithDisabledActions:^{
                [self renderContainedViewInLayer:self.layer];
            }];
        } else {
            [CATransaction performWithDisabledActions:^{
                self.layer.contents = nil;
            }];
        }
    }
}

@end
