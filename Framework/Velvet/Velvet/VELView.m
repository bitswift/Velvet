//
//  VELView.m
//  Velvet
//  
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSView+VELGeometryAdditions.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELViewPrivate.h>
#import <Velvet/VELViewProtected.h>
#import <Velvet/VELCAAction.h>
#import <Velvet/CGBitmapContext+PixelFormatAdditions.h>
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

/*
 * The affine transform needed to move into the coordinate system of the
 * receiver from its superview.
 */
@property (readonly) CGAffineTransform affineTransformFromSuperview;

/*
 * Returns the affine transform necessary to convert from the coordinate space
 * of the receiver to that of `parentView`. `parentView` must be an ancestor of
 * the receiver.
 */
- (CGAffineTransform)affineTransformToAncestorView:(VELView *)parentView;
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

        for (VELView *view in subviews) {
            [view removeFromSuperview];
        }

        m_subviews = [subviews copy];

        NSVelvetView *hostView = self.hostView;
        for (VELView *view in m_subviews) {
            [view willMoveToHostView:hostView];

            // match the context of this view with 'view'
            if (!view.context) {
                view.context = self.context;
            } else if (!self.context) {
                self.context = view.context;
            } else {
                NSAssert([view.context isEqual:self.context], @"VELContext of a new subview should match that of its superview");
            }

            view.superview = self;
            [self addSubviewToLayer:view];
            [view didMoveToHostView];
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
    NSUInteger depth = 0;
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

    for (VELView *view in self.subviews) {
        CGPoint subviewPoint = [view convertPoint:point fromView:self];
        VELView *hitView = [view hitTest:subviewPoint];
        if (hitView) {
            return hitView;
        }
    }

    return self;
}

#pragma mark Rendering

- (void)drawRect:(CGRect)rect; {
}

#pragma mark View hierarchy

- (void)addSubviewToLayer:(VELView *)view; {
    [self.layer addSublayer:view.layer];
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

- (CGAffineTransform)affineTransformFromSuperview {
    // this will expand in the future to include a 'transform' property
    CGRect frame = self.frame;
    return CGAffineTransformMakeTranslation(frame.origin.x, frame.origin.y);
}

- (CGAffineTransform)affineTransformToAncestorView:(VELView *)parentView; {
    NSParameterAssert([self isDescendantOfView:parentView]);

    CGAffineTransform affineTransform = CGAffineTransformIdentity;

    VELView *fromView = self;
    while (fromView != parentView) {
        // work backwards, getting the transformation from the superview to
        // the subview
        CGAffineTransform invertedTransform = fromView.affineTransformFromSuperview;

        // then invert that, to get the other direction
        affineTransform = CGAffineTransformConcat(affineTransform, CGAffineTransformInvert(invertedTransform));

        fromView = fromView.superview;
    }

    return CGAffineTransformInvert(affineTransform);
}

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
    CGAffineTransform transformToRoot = [self affineTransformToAncestorView:rootView];

    CGPoint hostPoint = CGPointApplyAffineTransform(point, transformToRoot);
    return [hostView convertToWindowPoint:hostPoint];
}

- (CGPoint)convertFromWindowPoint:(CGPoint)point {
    NSVelvetView *hostView = self.hostView;
    VELView *rootView = hostView.rootView;
    CGAffineTransform transformFromRoot = CGAffineTransformInvert([self affineTransformToAncestorView:rootView]);

    CGPoint hostPoint = [hostView convertFromWindowPoint:point];
    return CGPointApplyAffineTransform(hostPoint, transformFromRoot);
}

- (CGRect)convertToWindowRect:(CGRect)rect {
    NSVelvetView *hostView = self.hostView;
    VELView *rootView = hostView.rootView;
    CGAffineTransform transformToRoot = [self affineTransformToAncestorView:rootView];

    CGRect hostRect = CGRectApplyAffineTransform(rect, transformToRoot);
    return [hostView convertToWindowRect:hostRect];
}

- (CGRect)convertFromWindowRect:(CGRect)rect {
    NSVelvetView *hostView = self.hostView;
    VELView *rootView = hostView.rootView;
    CGAffineTransform transformFromRoot = CGAffineTransformInvert([self affineTransformToAncestorView:rootView]);

    CGRect hostRect = [hostView convertFromWindowRect:rect];
    return CGRectApplyAffineTransform(hostRect, transformFromRoot);
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

- (id < CAAction >)actionForLayer:(CALayer *)layer forKey:(NSString *)key
{
    // If we're being called inside the [layer actionForKey:key] call below,
    // retun nil, so that method will return the default action.
    if (self.recursingActionForLayer) return nil;

//    NSLog(@"ACTIONFORKEY. %@", key);

    self.recursingActionForLayer = YES;
    id <CAAction> innerAction = [layer actionForKey:key];
    self.recursingActionForLayer = NO;

    if ([VELCAAction interceptsActionForKey:key]) {
        return [VELCAAction actionWithAction:innerAction];
    } else {
        return innerAction;
    }
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
