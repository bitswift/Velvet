//
//  VELNSView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELNSView.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELViewPrivate.h>
#import <QuartzCore/QuartzCore.h>


@interface VELNSView ()
@property (nonatomic, assign) BOOL rendersContainedView;
@end


@implementation VELNSView

#pragma mark Properties

@synthesize NSView = m_NSView;
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
        if (view != m_NSView) [m_NSView removeFromSuperview];

        view.frame = [self.superview convertRect:self.frame toView:self.hostView.rootView];

        if (view != m_NSView) {
            [self.hostView addSubview:view];
            m_NSView = view;
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
    CGSize size = self.bounds.size;
    size_t width = (size_t)ceil(size.width);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
        NULL,
        width,
        (size_t)ceil(size.height),
        8,
        width * 4,
        colorSpace,
        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host
    );

    CGColorSpaceRelease(colorSpace);

    [self.NSView.layer renderInContext:context];

    CGImageRef image = CGBitmapContextCreateImage(context);
    layer.contents = (__bridge_transfer id)image;

    CGContextRelease(context);
}

- (void)withoutAnimation:(void(^)(void))block {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    block();
    [CATransaction commit];
}

- (void)setRendersContainedView:(BOOL)rendersContainedView {
    if (m_rendersContainedView != rendersContainedView) {
        m_rendersContainedView = rendersContainedView;
        if (rendersContainedView) {
            [self withoutAnimation:^{
                [self renderContainedViewInLayer:self.layer];
            }];
            self.NSView.alphaValue = 0.0;
        } else {
            self.NSView = self.NSView;
            self.NSView.alphaValue = 1.0;
            [self withoutAnimation:^{
                self.layer.contents = nil;
            }];
        }
    }
}

@end
