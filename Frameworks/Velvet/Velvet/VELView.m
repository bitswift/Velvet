//
//  VELView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELView.h>
#import <Proton/Proton.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/CGBitmapContext+PixelFormatAdditions.h>
#import <Velvet/NSColor+CoreGraphicsAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSVelvetViewPrivate.h>
#import <Velvet/NSView+ScrollViewAdditions.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/VELCAAction.h>
#import <Velvet/VELDraggingDestination.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/VELScrollView.h>
#import <Velvet/VELViewController.h>
#import <Velvet/VELViewPrivate.h>
#import <Velvet/VELViewProtected.h>
#import <objc/runtime.h>

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

/*
 * Whether the <VELView> hierarchy is currently performing a "deep" layout, in
 * which all views will be laid out if they need to be.
 *
 * In other words, this is `YES` if the current layout operation was triggered
 * by the layer tree.
 */
static BOOL VELViewPerformingDeepLayout = NO;

@interface VELView () {
    struct {
        unsigned userInteractionEnabled:1;
        unsigned recursingActionForLayer:1;
        unsigned clearsContextBeforeDrawing:1;
    } m_flags;

    NSMutableArray *m_subviews;
}

@property (nonatomic, readwrite, weak) VELView *superview;
@property (nonatomic, readwrite, weak) NSVelvetView *hostView;
@property (nonatomic, weak) VELViewController *viewController;

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

/*
 * Call the given block on the receiver and all of its subviews, recursively.
 */
- (void)recursivelyEnumerateViewsUsingBlock:(void(^)(VELView *))block;

/*
 * Removes the given view from the receiver's subview array, if present.
 *
 * This method modifies <subviews> and the layer hierarchy, and
 * updates the responder chain -- it does no additional bookkeeping and
 * does not invoke other methods.
 */
- (void)removeSubview:(VELView *)subview;

/*
 * Updates the next responder of the receiver and the receiver's view
 * controller.
 */
- (void)updateViewAndViewControllerNextResponders;
@end

@implementation VELView

#pragma mark Properties

@synthesize layer = m_layer;
@synthesize subviews = m_subviews;
@synthesize superview = m_superview;
@synthesize hostView = m_hostView;
@synthesize viewController = m_viewController;

- (BOOL)isRecursingActionForLayer {
    return m_flags.recursingActionForLayer;
}

- (void)setRecursingActionForLayer:(BOOL)recursing {
    m_flags.recursingActionForLayer = recursing;
}

- (BOOL)isUserInteractionEnabled {
    return m_flags.userInteractionEnabled;
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    m_flags.userInteractionEnabled = userInteractionEnabled;
}

- (BOOL)clearsContextBeforeDrawing {
    return m_flags.clearsContextBeforeDrawing;
}

- (void)setClearsContextBeforeDrawing:(BOOL)clearsContext {
    m_flags.clearsContextBeforeDrawing = clearsContext;
}

- (BOOL)clipsToBounds {
    return self.layer.masksToBounds;
}

- (void)setClipsToBounds:(BOOL)clipsToBounds {
    [[self class] changeLayerProperties:^{
        self.layer.masksToBounds = clipsToBounds;
    }];
}

// For geometry properties, it makes sense to reuse the layer's geometry,
// keeping them coupled as much as possible to allow easy modification of either
// (while affecting both).
- (CGRect)frame {
    return self.layer.frame;
}

- (void)setFrame:(CGRect)frame {
    CGSize originalSize = self.layer.frame.size;
    CGSize newSize = frame.size;
    
    [[self class] changeLayerProperties:^{
        self.layer.frame = frame;
    }];
    
    if (!CGSizeEqualToSize(originalSize, newSize)) {
        [self.layer setNeedsLayout];
        [self.layer layoutIfNeeded];
    } else {
        [self.subviews makeObjectsPerformSelector:@selector(ancestorDidLayout)];
    }
}

- (CGRect)bounds {
    return self.layer.bounds;
}

- (void)setBounds:(CGRect)bounds {
    BOOL needsLayout = !CGRectEqualToRect(bounds, self.layer.bounds);
    
    [[self class] changeLayerProperties:^{
        self.layer.bounds = bounds;
    }];
    
    if (needsLayout) {
        [self.layer setNeedsLayout];
        [self.layer layoutIfNeeded];
    }
}

- (CGPoint)center {
    return self.layer.position;
}

- (void)setCenter:(CGPoint)center {
    [[self class] changeLayerProperties:^{
        self.layer.position = center;
    }];
    [self.subviews makeObjectsPerformSelector:@selector(ancestorDidLayout)];
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

- (void)setSubviews:(NSArray *)newSubviews {
    NSMutableArray *oldSubviews = [m_subviews mutableCopy];

    if ([newSubviews count]) {
        m_subviews = [[NSMutableArray alloc] initWithCapacity:[newSubviews count]];

        // preserve any subviews we already had, but order them to match the input
        [newSubviews enumerateObjectsUsingBlock:^(VELView *view, NSUInteger newIndex, BOOL *stop){
            NSUInteger existingIndex = [oldSubviews indexOfObjectIdenticalTo:view];

            if (!oldSubviews || existingIndex == NSNotFound) {
                [self addSubview:view];
            } else {
                [oldSubviews removeObjectAtIndex:existingIndex];
                [m_subviews addObject:view];
            }
        }];
    } else {
        m_subviews = nil;
    }

    // at this point, 'oldSubviews' should only contain subviews which no longer
    // exist
    for (VELView *view in oldSubviews) {
        [view removeFromSuperview];
    }
}

- (NSVelvetView *)hostView {
    if (m_hostView)
        return m_hostView;
    else
        return self.superview.hostView;
}

- (void)setHostView:(NSVelvetView *)view {
    if (view == m_hostView)
        return;

    NSWindow *oldWindow = self.window;
    NSVelvetView *oldHostView = m_hostView;

    if (oldWindow != view.window)
        [self willMoveToWindow:view.window];

    [self willMoveToHostView:view];
    m_hostView = view;
    [self didMoveFromHostView:oldHostView];

    if (oldWindow != view.window)
        [self didMoveFromWindow:oldWindow];
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

- (void)setViewController:(VELViewController *)controller {
    // clear out the next responder of our previous view controller, since it's
    // no longer part of any chain
    m_viewController.nextResponder = nil;
    m_viewController = controller;

    [self updateViewAndViewControllerNextResponders];
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

    if ([[self class] doesCustomDrawing])
        self.contentMode = VELViewContentModeRedraw;
    else
        self.contentMode = VELViewContentModeScaleToFill;

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

- (void)setNeedsDisplayInRect:(CGRect)rect; {
    [self.layer setNeedsDisplayInRect:rect];
}

#pragma mark View hierarchy

- (void)addSubview:(VELView *)view; {
    if (view.superview == self)
        return;

    [CATransaction performWithDisabledActions:^{
        VELView *oldSuperview = view.superview;
        NSVelvetView *oldHostView = view.hostView;
        NSWindow *oldWindow = view.window;

        BOOL needsHostViewUpdate = (oldHostView != self.hostView);
        BOOL needsWindowUpdate = (oldWindow != self.window);

        if (needsWindowUpdate)
            [view willMoveToWindow:self.window];

        if (needsHostViewUpdate)
            [view willMoveToHostView:self.hostView];

        [view willMoveToSuperview:self];

        // remove the view from any existing superview (without calling the
        // normal -didMove and -willMove methods)
        [view.superview removeSubview:view];

        if (!m_subviews)
            m_subviews = [[NSMutableArray alloc] init];

        [m_subviews addObject:view];

        view.superview = self;
        [self addSubviewToLayer:view];

        [view didMoveFromSuperview:oldSuperview];

        if (needsHostViewUpdate)
            [view didMoveFromHostView:oldHostView];

        if (needsWindowUpdate)
            [view didMoveFromWindow:oldWindow];
    }];
}

- (void)addSubviewToLayer:(VELView *)view; {
    [self.layer addSublayer:view.layer];
}

- (void)ancestorDidLayout; {
    [self.subviews enumerateObjectsUsingBlock:^(VELView *subview, NSUInteger i, BOOL *stop){
        [subview ancestorDidLayout];
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

- (void)didMoveFromHostView:(id<VELHostView>)oldHostView {
    [self updateViewAndViewControllerNextResponders];

    if ([self respondsToSelector:@selector(supportedDragTypes)]) {
        [self.hostView registerDraggingDestination:(id)self];
    }

    [self.subviews makeObjectsPerformSelector:_cmd withObject:oldHostView];
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
    if (!self.superview)
        return;

    [self willMoveToWindow:nil];
    [self willMoveToHostView:nil];
    [self willMoveToSuperview:nil];

    VELView *superview = self.superview;
    NSVelvetView *hostView = self.hostView;
    NSWindow *window = self.window;

    [superview removeSubview:self];

    [self didMoveFromSuperview:superview];
    [self didMoveFromHostView:hostView];
    [self didMoveFromWindow:window];
}

- (void)removeSubview:(VELView *)subview; {
    [CATransaction performWithDisabledActions:^{
        id responder = [self.window firstResponder];
        if ([responder isKindOfClass:[VELView class]]) {
            if ([responder isDescendantOfView:subview]) {
                [self.window makeFirstResponder:self];
            }
        }

        [subview.layer removeFromSuperlayer];

        subview.superview = nil;
        [m_subviews removeObjectIdenticalTo:subview];
    }];
}

- (void)willMoveToHostView:(id<VELHostView>)hostView; {
    if ([self respondsToSelector:@selector(supportedDragTypes)]) {
        [self.hostView unregisterDraggingDestination:(id)self];
    }

    for (VELView *subview in self.subviews)
        [subview willMoveToHostView:hostView];
}

- (void)didMoveFromSuperview:(VELView *)superview; {
    [self updateViewAndViewControllerNextResponders];
    [self.subviews makeObjectsPerformSelector:_cmd withObject:superview];
}

- (void)didMoveFromWindow:(NSWindow *)window; {
    [self updateViewAndViewControllerNextResponders];

    if (self.window)
        [self.viewController viewDidAppear];
    else
        [self.viewController viewDidDisappear];

    [self.subviews makeObjectsPerformSelector:_cmd withObject:window];
}

- (void)willMoveToSuperview:(VELView *)superview; {
    [self.subviews makeObjectsPerformSelector:_cmd withObject:superview];
}

- (void)willMoveToWindow:(NSWindow *)window; {
    if (window)
        [self.viewController viewWillAppear];
    else
        [self.viewController viewWillDisappear];

    [self.subviews makeObjectsPerformSelector:_cmd withObject:window];
}

#pragma mark Responder chain

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)updateViewAndViewControllerNextResponders; {
    NSResponder *responderAfterViewController;

    if (self.superview)
        responderAfterViewController = self.superview;
    else if (self.hostView)
        responderAfterViewController = self.hostView;
    else
        responderAfterViewController = nil;

    if (self.viewController) {
        self.nextResponder = self.viewController;
        self.viewController.nextResponder = responderAfterViewController;
    } else {
        // no view controller, set the next responder as it would've been set on
        // our view controller
        self.nextResponder = responderAfterViewController;
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
    NSAssert(self.window, @"%@ window is nil!",self);
    
    NSVelvetView *hostView = self.hostView;

    VELView *rootView = hostView.rootView;
    CGPoint hostPoint = [self.layer convertPoint:point toLayer:rootView.layer];

    return [hostView convertToWindowPoint:hostPoint];
}

- (CGPoint)convertFromWindowPoint:(CGPoint)point {
    NSAssert(self.window, @"%@ window is nil!",self);
    
    NSVelvetView *hostView = self.hostView;
    CGPoint hostPoint = [hostView convertFromWindowPoint:point];

    VELView *rootView = hostView.rootView;
    return [self.layer convertPoint:hostPoint fromLayer:rootView.layer];
}

- (CGRect)convertToWindowRect:(CGRect)rect {
    NSAssert(self.window, @"%@ window is nil!",self);
    
    NSVelvetView *hostView = self.hostView;

    VELView *rootView = hostView.rootView;
    CGRect hostRect = [self.layer convertRect:rect toLayer:rootView.layer];

    return [hostView convertToWindowRect:hostRect];
}

- (CGRect)convertFromWindowRect:(CGRect)rect {
    NSAssert(self.window, @"%@ window is nil!",self);
    
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
    CGRect subviewsRect = CGRectZero;

    for (VELView *view in self.subviews) {
        subviewsRect = CGRectUnion(subviewsRect, view.frame);
    }

    return subviewsRect.size;
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

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    if (!context || ![[self class] doesCustomDrawing])
        return;

    CGRect drawingRegion = CGContextGetClipBoundingBox(context);

    if (self.clearsContextBeforeDrawing)
        CGContextClearRect(context, drawingRegion);

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

    [self drawRect:drawingRegion];

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
    if (![self pointInside:point])
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

- (BOOL)pointInside:(CGPoint)point {
    return CGRectContainsPoint(self.bounds, point);
}

#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    // we need to make sure to reset VELViewPerformingDeepLayout when exiting
    // this method, so it's simplest to just save its initial value
    BOOL wasDeepLayout = VELViewPerformingDeepLayout;

    VELViewPerformingDeepLayout = YES;

    [CATransaction performWithDisabledActions:^{
        [self layoutSubviews];

        // only one view needs to inform all descendants of a layout at the top,
        // so we start from the view which received the initial call to this
        // method
        if (!wasDeepLayout) {
            [self.subviews enumerateObjectsUsingBlock:^(VELView *subview, NSUInteger i, BOOL *stop){
                [subview ancestorDidLayout];
            }];
        }
    }];

    VELViewPerformingDeepLayout = wasDeepLayout;
}

- (CGSize)preferredSizeOfLayer:(CALayer *)layer {
    return [self sizeThatFits:CGSizeZero];
}

- (void)recursivelyEnumerateViewsUsingBlock:(void(^)(VELView *))block {
    block(self);
    for (VELView * view in self.subviews) {
        [view recursivelyEnumerateViewsUsingBlock:block];
    }
}


@end
