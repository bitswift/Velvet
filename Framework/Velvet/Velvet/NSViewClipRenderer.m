//
//  NSViewClipRenderer.m
//  Velvet
//
//  Created by Josh Vera on 11/26/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSViewClipRenderer.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/VELView.h>
#import <Velvet/VELNSView.h>
#import <QuartzCore/QuartzCore.h>
#import "EXTScope.h"

@interface NSViewClipRenderer ()
/*
 * The clip renderers used on the immediate sublayers of the receiver's layer.
 */
@property (nonatomic, strong, readonly) NSMutableArray *sublayerRenderers;

/*
 * The original delegate for the layer of the `NSView` that should be clipped.
 *
 * The receiver will forward delegate messages to this object once it has
 * performed the necessary setup.
 */
@property (nonatomic, strong, readonly) id originalLayerDelegate;

/*
 * The original layout manager for the layer of the `NSView` that should be
 * clipped.
 *
 * The receiver will forward layout messages to this object once it has
 * performed the necessary setup.
 */
@property (nonatomic, strong, readonly) id originalLayerLayoutManager;

/*
 * Returns `YES` if the given selector is part of the `CALayoutManager` informal
 * protocol.
 *
 * @param selector The selector to identify.
 */
+ (BOOL)isLayoutManagerSelector:(SEL)selector;

/*
 * Creates the array of <sublayerRenderers> based on the current sublayers of
 * the managed <layer>.
 */
- (void)setUpSublayerRenderers;
@end

@implementation NSViewClipRenderer

#pragma mark Properties

@synthesize originalLayerDelegate = m_originalLayerDelegate;
@synthesize originalLayerLayoutManager = m_originalLayerLayoutManager;
@synthesize clippedView = m_clippedView;
@synthesize layer = m_layer;
@synthesize sublayerRenderers = m_sublayerRenderers;

#pragma mark Lifecycle

- (id)init {
    return [self initWithClippedView:nil layer:nil];
}

- (id)initWithClippedView:(VELView *)clippedView layer:(CALayer *)layer; {
    self = [super init];
    if (!self)
        return nil;

    m_clippedView = clippedView;
    m_layer = layer;
    m_sublayerRenderers = [[NSMutableArray alloc] init];

    m_originalLayerDelegate = layer.delegate;
    layer.delegate = self;

    m_originalLayerLayoutManager = layer.layoutManager;
    layer.layoutManager = self;

    [self setUpSublayerRenderers];
    return self;
}

- (void)dealloc {
    self.layer.delegate = self.originalLayerDelegate;
    self.layer.layoutManager = self.originalLayerLayoutManager;
}

#pragma mark Rendering

- (void)clip; {
    [CATransaction performWithDisabledActions:^{
        [self.layer setNeedsDisplay];
        [self.layer displayIfNeeded];

        for (NSViewClipRenderer *renderer in self.sublayerRenderers) {
            [renderer clip];
        }
    }];
}

#pragma mark Sublayers

- (void)setUpSublayerRenderers; {
    NSArray *sublayers = self.layer.sublayers;

    [sublayers enumerateObjectsUsingBlock:^(CALayer *sublayer, NSUInteger index, BOOL *stop){
        for (NSViewClipRenderer *renderer in self.sublayerRenderers) {
            if (renderer.layer == sublayer)
                return;
        }

        [sublayer layoutIfNeeded];

        NSViewClipRenderer *renderer = [[[self class] alloc] initWithClippedView:self.clippedView layer:sublayer];
        [self.sublayerRenderers addObject:renderer];
    }];
}

#pragma mark Forwarding

- (id)forwardingTargetForSelector:(SEL)selector {
    if ([[self class] isLayoutManagerSelector:selector])
        return self.originalLayerLayoutManager;
    else
        return self.originalLayerDelegate;
}

- (BOOL)respondsToSelector:(SEL)selector {
    if ([[self class] isLayoutManagerSelector:selector]) {
        if ([[self class] instancesRespondToSelector:selector]) {
            return YES;
        }

        return [self.originalLayerLayoutManager respondsToSelector:selector];
    } else {
        if (selector != @selector(drawLayer:inContext:) && [[self class] instancesRespondToSelector:selector]) {
            return YES;
        }

        return [self.originalLayerDelegate respondsToSelector:selector];
    }
}

#pragma mark CALayer delegate

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)key {
    if ([self.originalLayerDelegate respondsToSelector:_cmd])
        return [self.originalLayerDelegate actionForLayer:layer forKey:key];

    return nil;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    if (!context)
        return;

    CGRect contextBounds = self.clippedView.layer.bounds;
    CGRect viewBounds = [self.clippedView.layer convertAndClipRect:contextBounds toLayer:layer];

    CGContextSaveGState(context);
    CGContextClipToRect(context, viewBounds);

    [self.originalLayerDelegate drawLayer:layer inContext:context];

    CGContextRestoreGState(context);
}

#pragma mark CALayoutManager

+ (BOOL)isLayoutManagerSelector:(SEL)selector; {
    if (selector == @selector(invalidateLayoutOfLayer:))
        return YES;

    if (selector == @selector(layoutSublayersOfLayer:))
        return YES;

    if (selector == @selector(preferredSizeOfLayer:))
        return YES;

    return NO;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [CATransaction performWithDisabledActions:^{
        if ([self.originalLayerDelegate respondsToSelector:_cmd]) {
            [self.originalLayerDelegate layoutSublayersOfLayer:layer];
        }

        [self setUpSublayerRenderers];
    }];
}

@end
