//
//  VELView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/CGBitmapContext+PixelFormatAdditions.h>
#import <Velvet/NSColor+CoreGraphicsAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/NSView+ScrollViewAdditions.h>
#import <Velvet/VELCAAction.h>
#import <Velvet/VELScrollView.h>
#import <Velvet/VELViewPrivate.h>
#import <Velvet/VELViewProtected.h>
#import <objc/runtime.h>
#import "EXTScope.h"

/*
 * The number of animation blocks currently being run.
 *
 * This is not how many animations are currently running, but instead how many
 * nested animations are being defined.
 */
static NSUInteger VELViewAnimationBlockDepth = 0;

/*
 * The function pointer to <VELView>'s implementation of <drawRect:>.
 *
 * This is compared against the pointers of any subclasses to determine whether
 * they provide their own implementation of the method.
 */
static IMP VELViewDrawRectIMP = NULL;

@interface VELView () {
    struct {
        unsigned userInteractionEnabled:1;
        unsigned recursingActionForLayer:1;
        unsigned clearsContextBeforeDrawing:1;
    } m_flags;
}

@property (nonatomic, readwrite, weak) VELView *superview;
@property (nonatomic, readwrite, weak) NSVelvetView *hostView;

/*
 * True if we're inside the `actionForLayer:forKey:` method. This is used so we
 * can get the original action for the key, and wrap it with extra functionality,
 * without entering an infinite loop.
 */
@property (nonatomic, assign, getter = isRecursingActionForLayer) BOOL recursingActionForLayer;

/*
 * Whether this view class does its own drawing, as determined by the
 * implementation of a <drawRect:> method.
 *
 * If this is `YES`, a bitmap context is automatically created for drawing, and
 * the results of any drawing are cached in its layer.
 */
+ (BOOL)doesCustomDrawing;
@end

@implementation VELView

#pragma mark Properties

@synthesize layer = m_layer;
@synthesize subviews = m_subviews;
@synthesize superview = m_superview;
@synthesize hostView = m_hostView;

- (BOOL)isRecursingActionForLayer {
    return (m_flags.recursingActionForLayer ? YES : NO);
}

- (void)setRecursingActionForLayer:(BOOL)recursing {
    m_flags.recursingActionForLayer = (recursing ? 1 : 0);
}

- (BOOL)isUserInteractionEnabled {
    return (m_flags.userInteractionEnabled ? YES : NO);
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    m_flags.userInteractionEnabled = (userInteractionEnabled ? 1 : 0);
}

- (BOOL)clearsContextBeforeDrawing {
    return (m_flags.clearsContextBeforeDrawing ? YES : NO);
}

- (void)setClearsContextBeforeDrawing:(BOOL)clearsContext {
    m_flags.clearsContextBeforeDrawing = (clearsContext ? 1 : 0);
}

// For geometry properties, it makes sense to reuse the layer's geometry,
// keeping them coupled as much as possible to allow easy modification of either
// (while affecting both).
- (CGRect)frame {
    return self.layer.frame;
}

- (void)setFrame:(CGRect)frame {
    [[self class] changeLayerProperties:^{
        self.layer.frame = frame;
    }];
}

- (CGRect)bounds {
    return self.layer.bounds;
}

- (void)setBounds:(CGRect)bounds {
    [[self class] changeLayerProperties:^{
        self.layer.bounds = bounds;
    }];
}

- (CGPoint)center {
    return self.layer.position;
}

- (void)setCenter:(CGPoint)center {
    [[self class] changeLayerProperties:^{
        self.layer.position = center;
    }];
}

- (VELViewAutoresizingMask)autoresizingMask {
    return self.layer.autoresizingMask;
}

- (void)setAutoresizingMask:(VELViewAutoresizingMask)autoresizingMask {
    [[self class] changeLayerProperties:^{
        self.layer.autoresizingMask = autoresizingMask;
    }];
}

- (CGAffineTransform)transform {
    CATransform3D layerTransform = self.layer.transform;
    if (CATransform3DIsAffine(layerTransform))
        return CATransform3DGetAffineTransform(layerTransform);
    else
        return CGAffineTransformIdentity;
}

- (void)setTransform:(CGAffineTransform)transform {
    [[self class] changeLayerProperties:^{
        self.layer.transform = CATransform3DMakeAffineTransform(transform);
    }];
}

- (CGFloat)alpha {
    return self.layer.opacity;
}

- (void)setAlpha:(CGFloat)alpha {
    [[self class] changeLayerProperties:^{
        self.layer.opacity = (float)alpha;
    }];
}

- (BOOL)isHidden {
    return self.layer.hidden;
}

- (void)setHidden:(BOOL)hidden {
    [[self class] changeLayerProperties:^{
        self.layer.hidden = hidden;
    }];
}

- (void)setSubviews:(NSArray *)subviews {
    for (VELView *view in m_subviews) {
        [view removeFromSuperview];
    }

    m_subviews = nil;

    for (VELView *view in subviews) {
        [self addSubview:view];
    }
}

- (NSVelvetView *)hostView {
    if (m_hostView)
        return m_hostView;
    else
        return self.superview.hostView;
}

- (void)setHostView:(NSVelvetView *)view {
    [self willMoveToHostView:view];
    m_hostView = view;
    [self didMoveToHostView];
}

- (NSColor *)backgroundColor {
    return [NSColor colorWithCGColor:self.layer.backgroundColor];
}

- (void)setBackgroundColor:(NSColor *)color {
    [[self class] changeLayerProperties:^{
        self.layer.backgroundColor = color.CGColor;
    }];
}

- (BOOL)isOpaque {
    return self.layer.opaque;
}

- (void)setOpaque:(BOOL)opaque {
    [[self class] changeLayerProperties:^{
        self.layer.opaque = opaque;
    }];
}

- (VELViewContentMode)contentMode {
    if (self.layer.needsDisplayOnBoundsChange)
        return VELViewContentModeRedraw;

    NSString *contentsGravity = self.layer.contentsGravity;

    // ordered roughly by expected frequency, to reduce the number of string
    // comparisons necessary
    if ([contentsGravity isEqualToString:kCAGravityResize]) {
        return VELViewContentModeScaleToFill;
    } else if ([contentsGravity isEqualToString:kCAGravityResizeAspect]) {
        return VELViewContentModeScaleAspectFit;
    } else if ([contentsGravity isEqualToString:kCAGravityResizeAspectFill]) {
        return VELViewContentModeScaleAspectFill;
    } else if ([contentsGravity isEqualToString:kCAGravityCenter]) {
        return VELViewContentModeCenter;
    } else if ([contentsGravity isEqualToString:kCAGravityTopLeft]) {
        return VELViewContentModeTopLeft;
    } else if ([contentsGravity isEqualToString:kCAGravityTop]) {
        return VELViewContentModeTop;
    } else if ([contentsGravity isEqualToString:kCAGravityBottom]) {
        return VELViewContentModeBottom;
    } else if ([contentsGravity isEqualToString:kCAGravityLeft]) {
        return VELViewContentModeLeft;
    } else if ([contentsGravity isEqualToString:kCAGravityRight]) {
        return VELViewContentModeRight;
    } else if ([contentsGravity isEqualToString:kCAGravityTopRight]) {
        return VELViewContentModeTopRight;
    } else if ([contentsGravity isEqualToString:kCAGravityBottomLeft]) {
        return VELViewContentModeBottomLeft;
    } else if ([contentsGravity isEqualToString:kCAGravityBottomRight]) {
        return VELViewContentModeBottomRight;
    }

    NSAssert1(NO, @"Unknown CALayer contentsGravity \"%@\"", contentsGravity);
    return VELViewContentModeRedraw;
}

- (void)setContentMode:(VELViewContentMode)contentMode {
    switch (contentMode) {
        case VELViewContentModeScaleToFill:
            self.layer.contentsGravity = kCAGravityResize;
            break;

        case VELViewContentModeScaleAspectFit:
            self.layer.contentsGravity = kCAGravityResizeAspect;
            break;

        case VELViewContentModeScaleAspectFill:
            self.layer.contentsGravity = kCAGravityResizeAspectFill;
            break;

        case VELViewContentModeCenter:
            self.layer.contentsGravity = kCAGravityCenter;
            break;

        case VELViewContentModeTop:
            self.layer.contentsGravity = kCAGravityTop;
            break;

        case VELViewContentModeBottom:
            self.layer.contentsGravity = kCAGravityBottom;
            break;

        case VELViewContentModeLeft:
            self.layer.contentsGravity = kCAGravityLeft;
            break;

        case VELViewContentModeRight:
            self.layer.contentsGravity = kCAGravityRight;
            break;

        case VELViewContentModeTopLeft:
            self.layer.contentsGravity = kCAGravityTopLeft;
            break;

        case VELViewContentModeTopRight:
            self.layer.contentsGravity = kCAGravityTopRight;
            break;

        case VELViewContentModeBottomLeft:
            self.layer.contentsGravity = kCAGravityBottomLeft;
            break;

        case VELViewContentModeBottomRight:
            self.layer.contentsGravity = kCAGravityBottomRight;
            break;

        default:
            NSAssert1(NO, @"Unknown VELViewContentMode %i", contentMode);
            // fall through in case assertions are disabled

        case VELViewContentModeRedraw:
            self.layer.contentsGravity = kCAGravityResize;
            self.layer.needsDisplayOnBoundsChange = YES;

            // return, don't break, because the other content modes disable
            // 'needsDisplayOnBoundsChange'
            return;
    }

    self.layer.needsDisplayOnBoundsChange = NO;
}

- (CGRect)contentStretch {
    return self.layer.contentsCenter;
}

- (void)setContentStretch:(CGRect)stretch {
    [[self class] changeLayerProperties:^{
        self.layer.contentsCenter = stretch;
    }];
}

- (NSWindow *)window {
    return self.hostView.window;
}

+ (BOOL)doesCustomDrawing {
    return VELViewDrawRectIMP != class_getMethodImplementation(self, @selector(drawRect:));
}

#pragma mark Layer handling

+ (Class)layerClass; {
    return [CALayer class];
}

#pragma mark Lifecycle

+ (void)initialize {
    if (self != [VELView class])
        return;

    // save our -drawRect: implementation pointer so we can differentiate ours
    // from that of any subclasses
    VELViewDrawRectIMP = class_getMethodImplementation(self, @selector(drawRect:));
}

- (id)init; {
    self = [super init];
    if (!self)
        return nil;

    // we don't even provide a setter for this ivar, because it should never
    // change after initialization
    m_layer = [[[self class] layerClass] layer];
    m_layer.delegate = self;

    self.userInteractionEnabled = YES;

    // prefer safer defaults over performant defaults -- disregarding safety (or
    // more correct rendering) in favor of performance should be explicit
    self.opaque = NO;
    self.clearsContextBeforeDrawing = YES;
    self.contentMode = VELViewContentModeRedraw;

    [self setNeedsDisplay];
    return self;
}

- (id)initWithFrame:(CGRect)frame; {
    self = [self init];
    if (!self)
        return nil;

    self.frame = frame;
    return self;
}

#pragma mark Rendering

- (void)drawRect:(CGRect)rect; {
}

- (BOOL)needsDisplay; {
    return self.layer.needsDisplay;
}

- (void)setNeedsDisplay; {
    [self.layer setNeedsDisplay];
}

#pragma mark View hierarchy

- (void)addSubview:(VELView *)view; {
    [CATransaction performWithDisabledActions:^{
        [view removeFromSuperview];
        [view willMoveToHostView:self.hostView];

        if (!m_subviews)
            m_subviews = [NSArray arrayWithObject:view];
        else
            m_subviews = [m_subviews arrayByAddingObject:view];

        view.superview = self;
        [self addSubviewToLayer:view];
        [view didMoveToHostView];
    }];
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
    VELView *parentView = self;

    do {
        if ([view isDescendantOfView:parentView])
            return parentView;

        parentView = parentView.superview;
    } while (parentView);

    return nil;
}

- (void)didMoveToHostView; {
    self.nextResponder = self.superview ?: self.hostView;

    for (VELView *subview in self.subviews)
        [subview didMoveToHostView];
}

- (id)ancestorScrollView; {
    VELView *superview = self.superview;
    if (superview)
        return superview.ancestorScrollView;

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
    [CATransaction performWithDisabledActions:^{
        [self willMoveToHostView:nil];
        
        id responder = [self.window firstResponder];
        if ([responder isKindOfClass:[VELView class]]) {
            if ([responder isDescendantOfView:self]) {
                [self.window makeFirstResponder:self.nextResponder];
            }
        }

        [self.layer removeFromSuperlayer];
        self.superview = nil;

        [self didMoveToHostView];
    }];
}

- (void)willMoveToHostView:(NSVelvetView *)hostView; {
    for (VELView *subview in self.subviews)
        [subview willMoveToHostView:hostView];
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

- (BOOL)needsLayout; {
    return self.layer.needsLayout;
}

- (void)setNeedsLayout; {
    [self.layer setNeedsLayout];
}

- (CGSize)sizeThatFits:(CGSize)constraint; {
    return self.bounds.size;
}

- (void)centeredSizeToFit; {
    [CATransaction performWithDisabledActions:^{
        CGPoint center = self.center;
        CGSize size = [self sizeThatFits:CGSizeZero];

        self.bounds = CGRectMake(0, 0, size.width, size.height);
        self.center = center;
    }];
}

#pragma mark Animations

+ (void)animate:(void (^)(void))animations; {
    [self animate:animations completion:^{}];
}

+ (void)animate:(void (^)(void))animations completion:(void (^)(void))completionBlock; {
    [CATransaction flush];

    [CATransaction begin];
    [CATransaction setDisableActions:NO];
    [CATransaction setCompletionBlock:completionBlock];

    ++VELViewAnimationBlockDepth;
    animations();
    --VELViewAnimationBlockDepth;

    [CATransaction commit];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations; {
    [self animateWithDuration:duration animations:animations completion:^{}];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(void))completionBlock; {
    [CATransaction flush];

    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];
    [CATransaction setDisableActions:NO];
    [CATransaction setCompletionBlock:completionBlock];

    ++VELViewAnimationBlockDepth;
    animations();
    --VELViewAnimationBlockDepth;

    [CATransaction commit];
}

+ (void)changeLayerProperties:(void (^)(void))changesBlock; {
    if ([self isAnimating]) {
        changesBlock();
    } else {
        [CATransaction performWithDisabledActions:changesBlock];
    }
}

+ (BOOL)isAnimating; {
    return VELViewAnimationBlockDepth > 0;
}

#pragma mark NSObject overrides

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> frame = %@, subviews = %@", [self class], self, NSStringFromRect(self.frame), self.subviews];
}

#pragma mark CALayer delegate

- (void)displayLayer:(CALayer *)layer {
    if (![[self class] doesCustomDrawing])
        return;

    CGRect bounds = self.bounds;
    if (CGRectIsEmpty(bounds) || CGRectIsNull(bounds)) {
        // can't do anything
        return;
    }

    CGContextRef context = CGBitmapContextCreateGeneric(bounds.size, !self.opaque);
    if (!context) {
        return;
    }

    // always allow antialiasing and sub-pixel antialiasing
    // these calls alone do not enable it -- they only make the context allow it
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetAllowsFontSmoothing(context, YES);
    CGContextSetAllowsFontSubpixelPositioning(context, YES);
    CGContextSetAllowsFontSubpixelQuantization(context, YES);

    [self drawLayer:layer inContext:context];

    CGImageRef image = CGBitmapContextCreateImage(context);
    layer.contents = (__bridge_transfer id)image;

    CGContextRelease(context);
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    if (!context || ![[self class] doesCustomDrawing])
        return;

    CGRect bounds = self.bounds;

    if (self.clearsContextBeforeDrawing)
        CGContextClearRect(context, bounds);

    CGContextClipToRect(context, bounds);

    // enable sub-pixel antialiasing (if drawing onto anything opaque)
    CGContextSetShouldAntialias(context, YES);
    CGContextSetShouldSmoothFonts(context, YES);
    CGContextSetShouldSubpixelPositionFonts(context, YES);
    CGContextSetShouldSubpixelQuantizeFonts(context, YES);

    NSGraphicsContext *previousGraphicsContext = [NSGraphicsContext currentContext];

    // push a new NSGraphicsContext representing this CGContext, which drawRect:
    // will render into
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
    [NSGraphicsContext setCurrentContext:graphicsContext];

    [self drawRect:bounds];

    [NSGraphicsContext setCurrentContext:previousGraphicsContext];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)key {
    if (![VELCAAction interceptsActionForKey:key])
        return nil;

    // If we're being called inside the [layer actionForKey:key] call below,
    // retun nil, so that method will return the default action.
    if (self.recursingActionForLayer)
        return nil;

    self.recursingActionForLayer = YES;
    id<CAAction> innerAction = [layer actionForKey:key];
    self.recursingActionForLayer = NO;

    return [VELCAAction actionWithAction:innerAction];
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
