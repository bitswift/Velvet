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
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/CALayer+GeometryAdditions.h>
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
@property (assign, getter = isRecursingActionForLayer) BOOL recursingActionForLayer;
@end

@implementation VELView

#pragma mark Properties

@synthesize layer = m_layer;
@synthesize subviews = m_subviews;
@synthesize superview = m_superview;
@synthesize hostView = m_hostView;
@synthesize recursingActionForLayer = m_recursingActionForLayer;

// TODO: we should probably flush the GCD queue of an old context before
// accepting a new one (to make sure there are no race conditions during
// a transition)
@synthesize context = m_context;

// For geometry properties, it makes sense to reuse the layer's geometry,
// keeping them coupled as much as possible to allow easy modification of either
// (while affecting both).
- (CGRect)frame {
    return self.layer.frame;
}

- (void)setFrame:(CGRect)frame {
    self.layer.frame = frame;
}

- (CGRect)bounds {
    return self.layer.bounds;
}

- (void)setBounds:(CGRect)bounds {
    self.layer.bounds = bounds;
}

- (CGPoint)center {
    return self.layer.position;
}

- (void)setCenter:(CGPoint)center {
    self.layer.position = center;
}

- (NSArray *)subviews {
    __block NSArray *subviews = nil;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        subviews = [m_subviews copy];
    });

    return subviews;
}

- (void)setSubviews:(NSArray *)subviews {
    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        for (VELView *view in m_subviews) {
            [view removeFromSuperview];
        }

        m_subviews = nil;

        for (VELView *view in subviews) {
            [self addSubview:view];
        }
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
    [self willMoveToHostView:view];
    @onExit {
        [self didMoveToHostView];
    };

    // TODO: the threading here isn't really safe, since it depends on having
    // a valid context with which to synchronize -- sometimes there may be no
    // context, which could introduce race conditions

    if (!view) {
        dispatch_sync_recursive(self.context.dispatchQueue, ^{
            m_hostView = nil;
            self.context = nil;
        });

        return;
    }

    VELContext *selfContext = self.context;
    VELContext *viewContext = view.context;

    dispatch_block_t block = ^{
        m_hostView = view;
        self.context = viewContext;
    };

    if (selfContext != viewContext) {
        // if 'selfContext' is NULL, it will (intentionally) short-circuit the list
        // of arguments here
        dispatch_multibarrier_sync(block, viewContext.dispatchQueue, selfContext.dispatchQueue, NULL);
    } else {
        dispatch_sync_recursive(selfContext.dispatchQueue, block);
    }
}

- (NSWindow *)window {
    return self.hostView.window;
}

- (NSUInteger)viewDepth {
    // naive implementation
    NSUInteger depth = 1;
    VELView *superview = self.superview;
    while (superview) {
        ++depth;
        superview = superview.superview;
    }

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

    return self;
}

#pragma mark Responder

- (VELView *)hitTest:(CGPoint)point; {
    if (!CGRectContainsPoint(self.bounds, point))
        return nil;

    __block VELView *result = self;

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

        // match the context of this view with 'view'
        if (!view.context) {
            view.context = self.context;
        } else if (!self.context) {
            self.context = view.context;
        } else {
            NSAssert([view.context isEqual:self.context], @"VELContext of a new subview should match that of its superview");
        }

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
    for (VELView *subview in self.subviews) {
        [subview ancestorDidScroll];
    }
}

- (VELView *)ancestorSharedWithView:(VELView *)view; {
    VELView *parentView = self;

    do {
        if ([view isDescendantOfView:parentView])
            return parentView;

        parentView = parentView.superview;
    } while (parentView);

    return nil;
}

- (void)didMoveToHostView; {
    for (VELView *subview in self.subviews) {
        [subview didMoveToHostView];
    }
}

- (id)ancestorScrollView; {
    if (self.superview)
        return self.superview.ancestorScrollView;

    return [self.hostView ancestorScrollView];
}

- (BOOL)isDescendantOfView:(VELView *)view; {
    NSParameterAssert(view != nil);

    VELView *testView = self;
    do {
        if (testView == view)
            return YES;

        testView = testView.superview;
    } while (testView);

    return NO;
}

- (void)removeFromSuperview; {
    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        [self willMoveToHostView:nil];

        [self.layer removeFromSuperlayer];
        self.superview = nil;

        [self didMoveToHostView];
    });
}

- (void)willMoveToHostView:(NSVelvetView *)hostView; {
    for (VELView *subview in self.subviews) {
        [subview willMoveToHostView:hostView];
    }
}

#pragma mark Geometry

- (CGPoint)convertPoint:(CGPoint)point fromView:(id<VELBridgedView>)view; {
    return [self convertFromWindowPoint:[view convertToWindowPoint:point]];
}

- (CGPoint)convertPoint:(CGPoint)point toView:(id<VELBridgedView>)view; {
    return [view convertFromWindowPoint:[self convertToWindowPoint:point]];
}

- (CGRect)convertRect:(CGRect)rect fromView:(id<VELBridgedView>)view; {
    return [self convertFromWindowRect:[view convertToWindowRect:rect]];
}

- (CGRect)convertRect:(CGRect)rect toView:(id<VELBridgedView>)view; {
    return [view convertFromWindowRect:[self convertToWindowRect:rect]];
}

#pragma mark VELBridgedView

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
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
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
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)key
{
    // If we're being called inside the [layer actionForKey:key] call below,
    // retun nil, so that method will return the default action.
    if (self.recursingActionForLayer)
        return nil;

//    NSLog(@"ACTIONFORKEY. %@", key);

    self.recursingActionForLayer = YES;
    id<CAAction> innerAction = [layer actionForKey:key];
    self.recursingActionForLayer = NO;

    if ([VELCAAction interceptsActionForKey:key]) {
        return [VELCAAction actionWithAction:innerAction];
    } else {
        return innerAction;
    }
}

- (id<VELBridgedView>)descendantViewAtPoint:(NSPoint)point {
    // Clip to self
    if (!CGRectContainsPoint(self.bounds, point))
        return nil;

    __block id<VELBridgedView> result = self;

    [self.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(VELView <VELBridgedView> *view, NSUInteger index, BOOL *stop){

        CGPoint subviewPoint = [view convertPoint:point fromView:self];

        id<VELBridgedView> hitTestedView = [view descendantViewAtPoint:subviewPoint];
        if (hitTestedView) {
            result = hitTestedView;
            *stop = YES;
        }
    }];

    return result;
}

#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [CATransaction performWithDisabledActions:^{
        [self layoutSubviews];
    }];
}

- (CGSize)preferredSizeOfLayer:(CALayer *)layer {
    return [self sizeThatFits:CGSizeZero];
}

@end
