//
//  VELFocusRingLayer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELFocusRingLayer.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/CGBitmapContext+PixelFormatAdditions.h>
#import <Velvet/VELView.h>

@interface VELFocusRingLayer ()
@property (nonatomic, weak, readonly) VELView *hostView;
@end

@implementation VELFocusRingLayer

#pragma mark Properties

@synthesize originalLayer = m_originalLayer;
@synthesize hostView = m_hostView;

#pragma mark Lifecycle

- (id)init {
    return [self initWithOriginalLayer:nil hostView:nil];
}

- (id)initWithOriginalLayer:(CALayer *)layer hostView:(VELView *)hostView; {
    self = [super init];
    if (!self)
        return nil;

    m_originalLayer = layer;
    m_originalLayer.hidden = YES;
    m_hostView = hostView;

    [self setNeedsDisplay];
    return self;
}

#pragma mark Rendering

- (void)drawInContext:(CGContextRef)context {
    CALayer *hostSuperlayer = self.hostView.layer.superlayer;
    if (!self.originalLayer || !hostSuperlayer)
        return;

    VELView *clippingView = [self.hostView ancestorScrollView];
    
    // only clip to scroll views of our creation
    if (![clippingView isKindOfClass:[VELView class]])
        clippingView = nil;

    CGContextSaveGState(context);

    if (clippingView) {
        CGRect contextBounds = clippingView.layer.bounds;
        CGRect viewBounds = [clippingView.layer convertAndClipRect:contextBounds toLayer:self];
        CGContextClipToRect(context, viewBounds);
    }

    [CATransaction performWithDisabledActions:^{
        self.originalLayer.hidden = NO;
        [self.originalLayer renderInContext:context];
        self.originalLayer.hidden = YES;
    }];

    CGContextRestoreGState(context);
}

@end
