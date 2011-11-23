//
//  VELView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSView+VELGeometryAdditions.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELViewPrivate.h>

@interface VELView ()
@property (readwrite, weak) VELView *superview;
@property (readwrite, weak) NSVelvetView *hostView;
@property (readwrite, strong) VELContext *context;

/**
 * The affine transform needed to move into the coordinate system of the
 * receiver from its superview.
 */
@property (readonly) CGAffineTransform affineTransformFromSuperview;

/**
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

        m_subviews = [subviews copy];
        for (VELView *view in m_subviews) {
            // match the context of this view with 'view'
            if (!view.context) {
                view.context = self.context;
            } else if (!self.context) {
                self.context = view.context;
            } else {
                NSAssert([view.context isEqual:self.context], @"VELContext of a new subview should match that of its superview");
            }

            view.superview = self;
            [self.layer addSublayer:view.layer];
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

#pragma mark Rendering

- (void)drawRect:(CGRect)rect; {
}

#pragma mark View hierarchy

- (VELView *)ancestorSharedWithView:(VELView *)view; {
    VELView *parentView = self;

    do {
        if ([view isDescendantOfView:parentView])
            return parentView;

        parentView = parentView.superview;
    } while (parentView);

    return nil;
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
        [self.layer removeFromSuperlayer];
        self.superview = nil;
    });
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

    return affineTransform;
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

#pragma mark CALayer delegate

- (void)displayLayer:(CALayer *)layer {
    CGSize size = self.bounds.size;
    size_t width = (size_t)ceil(size.width);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
        NULL,
        width,
        (size_t)ceil(size.height),
        8, // bits per component
        width * 4, // bytes per row
        colorSpace,

        // ARGB in host byte order (which is, incidentally, the only
        // CGBitmapInfo that correctly supports sub-pixel antialiasing text)
        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host
    );

    CGColorSpaceRelease(colorSpace);

    [self drawLayer:layer inContext:context];

    CGImageRef image = CGBitmapContextCreateImage(context);
    layer.contents = (__bridge_transfer id)image;

    CGContextRelease(context);
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
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

@end
