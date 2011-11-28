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
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSView+VELNSViewAdditions.h>
#import <Velvet/NSViewClipRenderer.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/VELViewProtected.h>
#import <QuartzCore/QuartzCore.h>

@interface VELNSView ()
@property (nonatomic, assign) BOOL rendersContainedView;

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

- (NSView *)NSView {
    __block NSView *view;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        view = m_NSView;
    });

    return view;
}

- (void)setNSView:(NSView *)view {
    // set up layer-backing on the view, so it will render into its layer as
    // soon as possible (without tying up the dispatch queue, if possible)
    [view setWantsLayer:YES];
    [view setNeedsDisplay:YES];

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        [m_NSView removeFromSuperview];
        m_NSView.layer.delegate = self.clipRenderer.originalLayerDelegate;
        m_NSView.hostView = nil;

        m_NSView = view;

        if (view) {
            view.hostView = self;

            [self.hostView addSubview:view];
            [self synchronizeNSViewGeometry];

            self.clipRenderer = [[NSViewClipRenderer alloc] init];
            self.clipRenderer.clippedView = self;
            self.clipRenderer.originalLayerDelegate = view.layer.delegate;
            view.layer.delegate = self.clipRenderer;
        } else {
            self.clipRenderer = nil;
        }
    });
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

    return self;
}

- (id)initWithNSView:(NSView *)view; {
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
    if (!self.hostView) {
        // can't do this without a host view
        return;
    }

    self.NSView.frame = self.NSViewFrame;

    // if the frame has changed, we'll need to go through our clipRenderer's
    // -drawLayer:inContext: logic again with the new location and size, so mark
    // the layer as needing display
    [self.NSView.layer setNeedsDisplay];
}

#pragma mark View hierarchy

- (void)ancestorDidScroll; {
    [self synchronizeNSViewGeometry];
    [super ancestorDidScroll];
}

- (void)willMoveToHostView:(NSVelvetView *)hostView {
    [self.NSView removeFromSuperview];
}

- (void)didMoveToHostView {
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
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [self synchronizeNSViewGeometry];
}

- (CGSize)sizeThatFits:(CGSize)constraint {
    id view = self.NSView;
    NSCell *cell = nil;
    NSSize cellSize = NSMakeSize(10000, 10000);

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
    CGContextRef context = CGBitmapContextCreateGeneric(self.bounds.size);

    [self.NSView.layer renderInContext:context];

    CGImageRef image = CGBitmapContextCreateImage(context);
    layer.contents = (__bridge_transfer id)image;

    CGContextRelease(context);
}

- (void)setRendersContainedView:(BOOL)rendersContainedView {
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
