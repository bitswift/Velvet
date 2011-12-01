//
//  VELView.m
//  Velvet
//  
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/CGBitmapContext+PixelFormatAdditions.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSView+VELGeometryAdditions.h>
#import <Velvet/NSView+ScrollViewAdditions.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELCAAction.h>
#import <Velvet/VELScrollView.h>
#import <Velvet/VELViewPrivate.h>
#import <Velvet/VELViewProtected.h>
#import "EXTScope.h"

@interface VELView ()
@property (readwrite, weak) VELView *superview;
@property (readwrite, weak) NSVelvetView *hostView;
@property (readwrite, strong) VELContext *context;

/*
 * True if we're inside the `actionForLayer:forKey:` method. This is used so we
 * can get the original action for the key, and wrap it with extra functionality,
 * without entering an infinite loop.
 */
@property (nonatomic, assign, getter = isRecursingActionForLayer) BOOL recursingActionForLayer;
@end

@implementation VELView

#pragma mark Properties

@synthesize layer = m_layer;
@synthesize subviews = m_subviews;
@synthesize superview = m_superview;
@synthesize hostView = m_hostView;
@synthesize recursingActionForLayer = m_recursingActionForLayer;
@synthesize canDrawConcurrently = m_canDrawConcurrently;
@synthesize context = m_context;

// For geometry properties, it makes sense to reuse the layer's geometry,
// keeping them coupled as much as possible to allow easy modification of either
// (while affecting both).
- (CGRect)frame {
    return self.layer.frame;
}

- (void)setFrame:(CGRect)frame {
    [CATransaction performWithDisabledActions:^{
        self.layer.frame = frame;
    }];
}

- (CGRect)bounds {
    return self.layer.bounds;
}

- (void)setBounds:(CGRect)bounds {
    [CATransaction performWithDisabledActions:^{
        self.layer.bounds = bounds;
    }];
}

- (CGPoint)center {
    return self.layer.position;
}

- (void)setCenter:(CGPoint)center {
    [CATransaction performWithDisabledActions:^{
        self.layer.position = center;
    }];
}

- (VELAutoresizingMask)autoresizingMask {
    return self.layer.autoresizingMask;
}

- (void)setAutoresizingMask:(VELAutoresizingMask)autoresizingMask {
    self.layer.autoresizingMask = autoresizingMask;
}

- (NSArray *)subviews {
    __block NSArray *subviews = nil;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        subviews = [m_subviews copy];
    });

    return subviews;
}

- (void)setSubviews:(NSArray *)subviews {
    dispatch_async(self.context.dispatchQueue, ^{
        for (VELView *view in m_subviews) {
            [view removeFromSuperview];
        }

        m_subviews = nil;

        for (VELView *view in subviews) {
            [self addSubview:view];
        }
    });
}

- (VELView *)superview {
    __block VELView *superview = nil;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        superview = m_superview;
    });

    return superview;
}

- (void)setSuperview:(VELView *)superview {
    dispatch_async(self.context.dispatchQueue, ^{
        m_superview = superview;
    });
}

- (NSVelvetView *)hostView {
    __block NSVelvetView *view = nil;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        view = m_hostView;
    });

    if (view)
        return view;
    else
        return self.superview.hostView;
}

- (void)setHostView:(NSVelvetView *)view {
    if (!view) {
        dispatch_sync_recursive(self.context.dispatchQueue, ^{
            [self willMoveToHostView:nil];
            m_hostView = nil;
            [self didMoveToHostView];
        });

        return;
    }

    dispatch_multibarrier_sync(^{
        self.context = view.context;
    
    // if 'self.context' is nil, it will (intentionally) short-circuit the list
    // of arguments here
    }, view.context.dispatchQueue, self.context.dispatchQueue, NULL);

    dispatch_async(self.context.dispatchQueue, ^{
        [self willMoveToHostView:view];
        m_hostView = view;
        [self didMoveToHostView];
    });
}

- (NSWindow *)window {
    return self.hostView.window;
}

- (NSUInteger)viewDepth {
    // naive implementation
    __block NSUInteger depth = 1;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        VELView *superview = self.superview;
        while (superview) {
            ++depth;
            superview = superview.superview;
        }
    });

    return depth;
}

#pragma mark Layer handling

+ (Class)layerClass; {
    return [CALayer class];
}

#pragma mark Lifecycle

- (id)init; {
    self = [super init];
    if (!self)
        return nil;

    // we don't even provide a setter for this ivar, because it should never
    // change after initialization
    m_layer = [[[self class] layerClass] layer];
    m_layer.delegate = self;
    m_layer.needsDisplayOnBoundsChange = YES;

    // set up a context so we get synchronization right off the bat
    self.context = [[VELContext alloc] init];

    return self;
}

- (id)initWithFrame:(CGRect)frame; {
    self = [self init];
    if (!self)
        return nil;

    self.frame = frame;
    return self;
}

#pragma mark Responder

- (VELView *)hitTest:(CGPoint)point; {
    if (!CGRectContainsPoint(self.bounds, point))
        return nil;

    __block VELView *result = self;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        // subviews are ordered back-to-front, but we should test for hits in the
        // opposite order
        [self.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(VELView *view, NSUInteger index, BOOL *stop){
            CGPoint subviewPoint = [view convertPoint:point fromView:self];
            VELView *hitView = [view hitTest:subviewPoint];
            if (hitView) {
                result = hitView;
                *stop = YES;
            }
        }];
    });

    return result;
}

#pragma mark Rendering

- (void)drawRect:(CGRect)rect; {
}

#pragma mark View hierarchy

- (void)addSubview:(VELView *)view; {
    [view removeFromSuperview];

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        [view willMoveToHostView:self.hostView];

        dispatch_sync_recursive(view.context.dispatchQueue, ^{
            // match the context of this view with 'view'
            if (!self.context) {
                self.context = view.context;
            } else {
                view.context = self.context;
            }
        });

        if (!m_subviews)
            m_subviews = [NSArray arrayWithObject:view];
        else
            m_subviews = [m_subviews arrayByAddingObject:view];

        view.superview = self;
        [self addSubviewToLayer:view];
        [view didMoveToHostView];
    });
}

- (void)addSubviewToLayer:(VELView *)view; {
    [self.layer addSublayer:view.layer];
}

- (void)ancestorDidScroll; {
    [self.subviews enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(VELView *subview, NSUInteger i, BOOL *stop){
        [subview ancestorDidScroll];
    }];
}

- (VELView *)ancestorSharedWithView:(VELView *)view; {
    __block VELView *parentView = self;

    dispatch_sync_recursive(view.context.dispatchQueue, ^{
        do {
            if ([view isDescendantOfView:parentView]) 
                return;

            parentView = parentView.superview;
        } while (parentView);
    });

    return parentView;
}

- (void)didMoveToHostView; {
    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        for (VELView *subview in self.subviews)
            [subview didMoveToHostView];
    });
}

- (id)ancestorScrollView; {
    VELView *superview = self.superview;
    if (superview)
        return superview.ancestorScrollView;

    return [self.hostView ancestorScrollView];
}

- (BOOL)isDescendantOfView:(VELView *)view; {
    NSParameterAssert(view != nil);

    __block VELView *testView = self;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        do {
            if (testView == view)
                return;

            testView = testView.superview;
        } while (testView);
    });

    return (testView != nil);
}

- (void)removeFromSuperview; {
    dispatch_async(self.context.dispatchQueue, ^{
        [self willMoveToHostView:nil];

        [self.layer removeFromSuperlayer];
        self.superview = nil;

        [self didMoveToHostView];
    });
}

- (void)willMoveToHostView:(NSVelvetView *)hostView; {
    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        for (VELView *subview in self.subviews)
            [subview willMoveToHostView:hostView];
    });
}

#pragma mark Geometry

- (CGPoint)convertPoint:(CGPoint)point fromView:(id<VELGeometry>)view; {
    return [self convertFromWindowPoint:[view convertToWindowPoint:point]];
}

- (CGPoint)convertPoint:(CGPoint)point toView:(id<VELGeometry>)view; {
    return [view convertFromWindowPoint:[self convertToWindowPoint:point]];
}

- (CGRect)convertRect:(CGRect)rect fromView:(id<VELGeometry>)view; {
    return [self convertFromWindowRect:[view convertToWindowRect:rect]];
}

- (CGRect)convertRect:(CGRect)rect toView:(id<VELGeometry>)view; {
    return [view convertFromWindowRect:[self convertToWindowRect:rect]];
}

#pragma mark VELGeometry

- (CGPoint)convertToWindowPoint:(CGPoint)point {
    NSVelvetView *hostView = self.hostView;

    VELView *rootView = hostView.rootView;
    CGPoint hostPoint = [self.layer convertPoint:point toLayer:rootView.layer];

    return [hostView convertToWindowPoint:hostPoint];
}

- (CGPoint)convertFromWindowPoint:(CGPoint)point {
    NSVelvetView *hostView = self.hostView;
    CGPoint hostPoint = [hostView convertFromWindowPoint:point];

    VELView *rootView = hostView.rootView;
    return [self.layer convertPoint:hostPoint fromLayer:rootView.layer];
}

- (CGRect)convertToWindowRect:(CGRect)rect {
    NSVelvetView *hostView = self.hostView;

    VELView *rootView = hostView.rootView;
    CGRect hostRect = [self.layer convertRect:rect toLayer:rootView.layer];

    return [hostView convertToWindowRect:hostRect];
}

- (CGRect)convertFromWindowRect:(CGRect)rect {
    NSVelvetView *hostView = self.hostView;
    CGRect hostRect = [hostView convertFromWindowRect:rect];

    VELView *rootView = hostView.rootView;
    return [self.layer convertRect:hostRect fromLayer:rootView.layer];
}

#pragma mark Layout

- (void)layoutSubviews; {
}

- (CGSize)sizeThatFits:(CGSize)constraint; {
    return self.bounds.size;
}

#pragma mark NSObject overrides

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> frame = %@, subviews = %@", [self class], self, NSStringFromRect(self.frame), self.subviews];
}

#pragma mark CALayer delegate

- (void)displayLayer:(CALayer *)layer {
    dispatch_block_t displayBlock = ^{
        CGRect bounds = self.bounds;
        if (CGRectIsEmpty(bounds) || CGRectIsNull(bounds)) {
            // can't do anything
            return;
        }

        CGContextRef context = CGBitmapContextCreateGeneric(bounds.size);
        if (!context) {
            return;
        }

        [self drawLayer:layer inContext:context];

        CGImageRef image = CGBitmapContextCreateImage(context);
        layer.contents = (__bridge_transfer id)image;

        CGContextRelease(context);
    };

    if (self.canDrawConcurrently)
        dispatch_async(self.context.dispatchQueue, displayBlock);
    else
        displayBlock();
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    dispatch_block_t displayBlock = ^{
        if (!context)
            return;

        CGRect bounds = self.bounds;

        CGContextClearRect(context, bounds);
        CGContextClipToRect(context, bounds);

        // enable sub-pixel antialiasing (if drawing onto anything opaque)
        CGContextSetShouldSmoothFonts(context, YES);

        NSGraphicsContext *previousGraphicsContext = [NSGraphicsContext currentContext];

        // push a new NSGraphicsContext representing this CGContext, which drawRect:
        // will render into
        NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
        [NSGraphicsContext setCurrentContext:graphicsContext];

        [self drawRect:bounds];

        [NSGraphicsContext setCurrentContext:previousGraphicsContext];
    };

    if (self.canDrawConcurrently)
        dispatch_sync_recursive(self.context.dispatchQueue, displayBlock);
    else
        dispatch_sync_recursive(dispatch_get_main_queue(), displayBlock);
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)key {
    // since 'recursingActionForLayer' isn't thread-safe, we have to make sure that
    // this whole chain of events only happens on one thread
    [CATransaction lock];
    @onExit {
        [CATransaction unlock];
    };

    // If we're being called inside the [layer actionForKey:key] call below,
    // retun nil, so that method will return the default action.
    if (self.recursingActionForLayer) return nil;

    self.recursingActionForLayer = YES;
    id<CAAction> innerAction = [layer actionForKey:key];
    self.recursingActionForLayer = NO;

    if ([VELCAAction interceptsActionForKey:key]) {
        return [VELCAAction actionWithAction:innerAction];
    } else {
        return innerAction;
    }
}

#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    dispatch_async(self.context.dispatchQueue, ^{
        [CATransaction performWithDisabledActions:^{
            [self layoutSubviews];
        }];

        [CATransaction flush];
    });
}

- (CGSize)preferredSizeOfLayer:(CALayer *)layer {
    __block CGSize size;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        size = [self sizeThatFits:CGSizeZero];
    });

    return size;
}

@end
