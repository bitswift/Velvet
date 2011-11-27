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
#import <Velvet/NSViewClipRenderer.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/VELViewPrivate.h>
#import <QuartzCore/QuartzCore.h>

@interface VELNSView ()
@property (nonatomic, assign) BOOL rendersContainedView;
@property (nonatomic, strong) NSViewClipRenderer *clipRenderer;
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
        if (view != m_NSView) {
            [m_NSView removeFromSuperview];
            m_NSView.layer.delegate = self.clipRenderer.originalLayerDelegate;
        }

        view.frame = [self.superview convertRect:self.frame toView:self.hostView.rootView];

        if (view != m_NSView) {
            m_NSView = view;

            if (view) {
                [self.hostView addSubview:view];

                self.clipRenderer = [[NSViewClipRenderer alloc] init];
                self.clipRenderer.clippedView = self;
                self.clipRenderer.originalLayerDelegate = view.layer.delegate;
                view.layer.delegate = self.clipRenderer;
            } else {
                self.clipRenderer = nil;
            }
        }
    });
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
    return self;
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
