//
//  VELView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELView.h"
#import "CALayer+GeometryAdditions.h"
#import "CATransaction+BlockAdditions.h"
#import "CGBitmapContext+PixelFormatAdditions.h"
#import "NSColor+CoreGraphicsAdditions.h"
#import "NSVelvetView.h"
#import "NSVelvetViewPrivate.h"
#import "NSView+VELBridgedViewAdditions.h"
#import "VELCAAction.h"
#import "VELDraggingDestination.h"
#import "VELHostView.h"
#import "VELNSViewPrivate.h"
#import "VELViewController.h"
#import "VELViewLayer.h"
#import "VELViewPrivate.h"
#import <objc/runtime.h>
#import "EXTScope.h"

/*
 * The number of animation blocks currently being run.
 *
 * This is not how many animations are currently running, but instead how many
 * nested animations are being defined.
 */
static NSUInteger VELViewCurrentAnimationBlockDepth = 0;

/*
 * The animation options for the current animation block, if any.
 */
static VELViewAnimationOptions VELViewCurrentAnimationOptions = 0;

/*
 * Keeps track of any layers that need to be laid out before the current
 * animation block is committed.
 *
 * The layers should be marked as needing layout before being added to this set.
 *
 * This should always be set to `nil` after all animations are committed, to
 * make sure the array is properly released.
 */
static NSMutableSet *VELViewCurrentAnimationLayersNeedingLayout = nil;

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
        unsigned alignsToIntegralPixels:1;
        unsigned replacingSubviews:1;
    } m_flags;

    /*
     * A mutable array backing the immutable <subviews> property.
     *
     * We expose this array as immutable to prevent callers from reordering or
     * directly modifying the subviews array, instead requiring the use of the
     * specific interface methods for doing so.
     */
    NSMutableArray *m_subviews;
}

@property (nonatomic, readwrite, weak) VELView *superview;
@property (nonatomic, weak) VELViewController *viewController;

/*
 * True if we're inside the `actionForLayer:forKey:` method. This is used so we
 * can get the original action for the key, and wrap it with extra functionality,
 * without entering an infinite loop.
 */
@property (nonatomic, assign, getter = isRecursingActionForLayer) BOOL recursingActionForLayer;

/*
 * Whether the receiver is currently in the process of replacing all its
 * subviews.
 *
 * This should be used to stifle KVO notifications from adding/removing
 * individual subviews (since only the KVO notification for the whole
 * replacement should be sent).
 */
@property (nonatomic, assign, getter = isReplacingSubviews) BOOL replacingSubviews;

/*
 * Runs a block to change properties on one or more layers, taking into account
 * whether <VELView> animations are currently enabled.
 *
 * If this is run from inside an animation block, the changes are animated as
 * part of the animation. Otherwise, the changes take effect immediately,
 * without animation.
 *
 * @param changesBlock A block containing changes to make to layers.
 */
- (void)changeLayerProperties:(void (^)(void))changesBlock;

/**
 * Whether changes are currently being added to an animation.
 *
 * This is not whether an animation is currently in progress, but whether the
 * calling code is running from an animation block.
 */
+ (BOOL)isDefiningAnimation;

/*
 * Call the given block on the receiver and all of its subviews, recursively.
 */
- (void)recursivelyEnumerateViewsUsingBlock:(void (^)(VELView *))block;

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

@synthesize hostView = m_hostView;
@synthesize layer = m_layer;
@synthesize subviews = m_subviews;
@synthesize superview = m_superview;
@synthesize viewController = m_viewController;

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"subviews"]) {
        // KVO compliance for self.subviews is implemented manually
        return NO;
    }

    return [super automaticallyNotifiesObserversForKey:key];
}

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

- (BOOL)alignsToIntegralPixels {
    return m_flags.alignsToIntegralPixels;
}

- (void)setAlignsToIntegralPixels:(BOOL)aligns {
    m_flags.alignsToIntegralPixels = aligns;
}

- (BOOL)isReplacingSubviews {
    return m_flags.replacingSubviews;
}

- (void)setReplacingSubviews:(BOOL)replacing {
    m_flags.replacingSubviews = replacing;
}

- (BOOL)clipsToBounds {
    return self.layer.masksToBounds;
}

- (void)setClipsToBounds:(BOOL)clipsToBounds {
    [self changeLayerProperties:^{
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
    if (self.alignsToIntegralPixels) {
        frame = [self backingAlignedRect:frame];
    }

    CGSize originalSize = self.layer.frame.size;
    CGSize newSize = frame.size;
    
    [self changeLayerProperties:^{
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
    if (self.alignsToIntegralPixels) {
        bounds = [self backingAlignedRect:bounds];
    }

    BOOL needsLayout = !CGRectEqualToRect(bounds, self.layer.bounds);
    
    [self changeLayerProperties:^{
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
    if (self.alignsToIntegralPixels) {
        CGSize size = self.bounds.size;

        CGRect resultingFrame = CGRectMake(
            center.x - size.width / 2,
            center.y - size.height / 2,
            size.width,
            size.height
        );

        CGRect integralFrame = [self backingAlignedRect:resultingFrame];

        // this point may have fractional coordinates in it, but it'll result in
        // a frame which lands on whole pixels
        center = CGPointMake(CGRectGetMidX(integralFrame), CGRectGetMidY(integralFrame));
    }

    [self changeLayerProperties:^{
        self.layer.position = center;
    }];

    [self.subviews makeObjectsPerformSelector:@selector(ancestorDidLayout)];
}

- (VELViewAutoresizingMask)autoresizingMask {
    return self.layer.autoresizingMask;
}

- (void)setAutoresizingMask:(VELViewAutoresizingMask)autoresizingMask {
    self.layer.autoresizingMask = autoresizingMask;
}

- (CGAffineTransform)transform {
    CATransform3D layerTransform = self.layer.transform;
    if (CATransform3DIsAffine(layerTransform))
        return CATransform3DGetAffineTransform(layerTransform);
    else
        return CGAffineTransformIdentity;
}

- (void)setTransform:(CGAffineTransform)transform {
    [self changeLayerProperties:^{
        self.layer.transform = CATransform3DMakeAffineTransform(transform);
    }];
}

- (CGFloat)alpha {
    return self.layer.opacity;
}

- (void)setAlpha:(CGFloat)alpha {
    [self changeLayerProperties:^{
        self.layer.opacity = (float)alpha;
    }];
}

- (BOOL)isHidden {
    return self.layer.hidden;
}

- (void)setHidden:(BOOL)hidden {
    [self changeLayerProperties:^{
        self.layer.hidden = hidden;
    }];
}

- (void)setSubviews:(NSArray *)newSubviews {
    self.replacingSubviews = YES;
    [self willChangeValueForKey:@"subviews"];

    @onExit {
        [self didChangeValueForKey:@"subviews"];
        self.replacingSubviews = NO;
    };

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

- (id<VELHostView>)hostView {
    if (m_hostView)
        return m_hostView;
    else
        return self.superview.hostView;
}

- (void)setHostView:(id<VELHostView>)view {
    if (view == m_hostView)
        return;

    // this autorelease pool seems to be necessary to avoid keeping something
    // (don't know what) alive for too long after the host view has been
    // destroyed
    @autoreleasepool {
        NSVelvetView *oldVelvetView = self.ancestorNSVelvetView;
        NSVelvetView *newVelvetView = view.ancestorNSVelvetView;

        NSWindow *oldWindow = oldVelvetView.window;
        NSWindow *newWindow = newVelvetView.window;

        if (oldWindow != newWindow)
            [self willMoveToWindow:newWindow];
        
        if (oldVelvetView != newVelvetView)
            [self willMoveToNSVelvetView:newVelvetView];

        m_hostView = view;

        // the hostView may need to become our nextResponder
        [self updateViewAndViewControllerNextResponders];

        if (oldVelvetView != newVelvetView)
            [self didMoveFromNSVelvetView:oldVelvetView];

        if (oldWindow != newWindow)
            [self didMoveFromWindow:oldWindow];
    }
}

- (NSColor *)backgroundColor {
    return [NSColor colorWithCGColor:self.layer.backgroundColor];
}

- (void)setBackgroundColor:(NSColor *)color {
    [self changeLayerProperties:^{
        self.layer.backgroundColor = color.CGColor;
    }];
}

- (BOOL)isOpaque {
    return self.layer.opaque;
}

- (void)setOpaque:(BOOL)opaque {
    self.layer.opaque = opaque;
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
    [self changeLayerProperties:^{
        self.layer.contentsCenter = stretch;
    }];
}

- (NSWindow *)window {
    return self.ancestorNSVelvetView.window;
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
    return [VELViewLayer class];
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
    self.alignsToIntegralPixels = YES;

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

- (void)dealloc {
    m_layer.delegate = nil;

    NSUndoManager *undoManager = self.undoManager;

    if (undoManager) {
        [self recursivelyEnumerateViewsUsingBlock:^(VELView *descendant){
            [undoManager removeAllActionsWithTarget:descendant];
        }];
    }

    // remove 'self' as the next responder on any subviews
    for (VELView *view in self.subviews) {
        if (view.nextResponder == self)
            view.nextResponder = nil;
        else if (view.viewController.nextResponder == self)
            view.viewController.nextResponder = nil;
    }
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

    NSUInteger index = [m_subviews count];
    NSIndexSet *indexSet = nil;

    if (!self.replacingSubviews) {
        indexSet = [NSIndexSet indexSetWithIndex:index];

        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"subviews"];
    }

    @onExit {
        if (!self.replacingSubviews) {
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"subviews"];
        }
    };

    [CATransaction performWithDisabledActions:^{
        VELView *oldSuperview = view.superview;

        NSVelvetView *oldVelvetView = view.ancestorNSVelvetView;
        NSVelvetView *newVelvetView = self.ancestorNSVelvetView;

        NSWindow *oldWindow = view.window;
        NSWindow *newWindow = self.window;

        BOOL needsVelvetViewUpdate = (oldVelvetView != newVelvetView);
        BOOL needsWindowUpdate = (oldWindow != newWindow);

        if (needsWindowUpdate)
            [view willMoveToWindow:newWindow];

        if (needsVelvetViewUpdate)
            [view willMoveToNSVelvetView:newVelvetView];

        [view willMoveToSuperview:self];

        // remove the view from any existing superview (without calling the
        // normal -didMove and -willMove methods)
        [view.superview removeSubview:view];

        if (!m_subviews)
            m_subviews = [[NSMutableArray alloc] init];

        [m_subviews addObject:view];

        view.superview = self;
        [self.layer addSublayer:view.layer];

        [view didMoveFromSuperview:oldSuperview];

        if (needsVelvetViewUpdate)
            [view didMoveFromNSVelvetView:oldVelvetView];

        if (needsWindowUpdate)
            [view didMoveFromWindow:oldWindow];
    }];
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
    [self willMoveToNSVelvetView:nil];
    [self willMoveToSuperview:nil];

    VELView *superview = self.superview;
    NSVelvetView *velvetView = self.ancestorNSVelvetView;
    NSWindow *window = self.window;

    id responder = [window firstResponder];
    if ([responder isKindOfClass:[VELView class]]) {
        if ([responder isDescendantOfView:self]) {
            [window makeFirstResponder:self.nextResponder];
        }
    }

    [CATransaction performWithDisabledActions:^{
        [self.layer removeFromSuperlayer];
    }];

    [superview removeSubview:self];
    self.superview = nil;

    [self didMoveFromSuperview:superview];
    [self didMoveFromNSVelvetView:velvetView];
    [self didMoveFromWindow:window];
}

- (void)removeSubview:(VELView *)subview; {
    NSUInteger index = [m_subviews indexOfObjectIdenticalTo:subview];
    if (index == NSNotFound)
        return;

    NSIndexSet *indexSet = nil;

    if (!self.replacingSubviews) {
        indexSet = [NSIndexSet indexSetWithIndex:index];

        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"subviews"];
    }

    @onExit {
        if (!self.replacingSubviews) {
            [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"subviews"];
        }
    };

    [m_subviews removeObjectAtIndex:index];
}

- (void)didMoveFromSuperview:(VELView *)superview; {
    [self updateViewAndViewControllerNextResponders];
    [self.subviews makeObjectsPerformSelector:_cmd withObject:superview];
}

- (void)didMoveFromWindow:(NSWindow *)window; {
    CGFloat newScaleFactor = self.window.backingScaleFactor;

    if (newScaleFactor > 0 && fabs(newScaleFactor - self.layer.contentsScale) > 0.01) {
        // we just moved to a window that has a different pixel density, so
        // redisplay our layer at that scale factor
        self.layer.contentsScale = newScaleFactor;
        [self setNeedsDisplay];
    }

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
        responderAfterViewController = (id)self.hostView;
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

- (CGRect)backingAlignedRect:(CGRect)rect; {
    NSAlignmentOptions alignmentOptions =
        // floor(originX)
        NSAlignMinXOutward |

        // ceil(originY)
        NSAlignMinYInward |

        // floor(width)
        NSAlignWidthInward |

        // floor(height)
        NSAlignHeightInward;

    NSVelvetView *velvetView = self.ancestorNSVelvetView;
    NSWindow *window = velvetView.window;

    if (!window) {
        // try to align to the main screen's scale factor
        //
        // note that this may yield incorrect results if the view is actually
        // displayed on a different screen
        CGFloat scaleFactor = [[NSScreen mainScreen] backingScaleFactor];

        // convert to device space
        CGAffineTransform transformToBacking = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
        CGRect backingRect = CGRectApplyAffineTransform(rect, transformToBacking);

        // align the rectangle on pixels
        backingRect = NSIntegralRectWithOptions(backingRect, alignmentOptions);

        // convert back to user space
        return CGRectApplyAffineTransform(backingRect, CGAffineTransformInvert(transformToBacking));
    }

    CGRect windowRect = [self convertToWindowRect:rect];

    // the documentation says that the input rect is in view coordinates, but
    // it's actually window coordinates
    windowRect = [velvetView backingAlignedRect:windowRect options:alignmentOptions];

    return [self convertFromWindowRect:windowRect];
}

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
    
    NSVelvetView *hostView = self.ancestorNSVelvetView;
    CGPoint hostPoint = [self.layer convertPoint:point toLayer:hostView.layer];

    return [hostView convertToWindowPoint:hostPoint];
}

- (CGPoint)convertFromWindowPoint:(CGPoint)point {
    NSAssert(self.window, @"%@ window is nil!",self);
    
    NSVelvetView *hostView = self.ancestorNSVelvetView;
    CGPoint hostPoint = [hostView convertFromWindowPoint:point];

    return [self.layer convertPoint:hostPoint fromLayer:hostView.layer];
}

- (CGRect)convertToWindowRect:(CGRect)rect {
    NSAssert(self.window, @"%@ window is nil!",self);
    
    NSVelvetView *hostView = self.ancestorNSVelvetView;
    CGRect hostRect = [self.layer convertRect:rect toLayer:hostView.layer];

    return [hostView convertToWindowRect:hostRect];
}

- (CGRect)convertFromWindowRect:(CGRect)rect {
    NSAssert(self.window, @"%@ window is nil!",self);
    
    NSVelvetView *hostView = self.ancestorNSVelvetView;
    CGRect hostRect = [hostView convertFromWindowRect:rect];

    return [self.layer convertRect:hostRect fromLayer:hostView.layer];
}

- (id)ancestorScrollView; {
    VELView *superview = self.superview;
    if (superview)
        return superview.ancestorScrollView;

    return [self.hostView ancestorScrollView];
}

- (NSVelvetView *)ancestorNSVelvetView; {
    id<VELHostView> hostView = self.hostView;

    if ([hostView isKindOfClass:[NSVelvetView class]])
        return (id)hostView;

    return hostView.ancestorNSVelvetView;
}

- (void)didMoveFromNSVelvetView:(NSVelvetView *)view; {
    if (self.alignsToIntegralPixels) {
        // this NSVelvetView might be on a different window or a different screen,
        // and thus have a different pixel density, so we should re-align our
        // frame to integral pixels
        self.frame = self.layer.frame;
    }

    if ([self respondsToSelector:@selector(supportedDragTypes)]) {
        [self.ancestorNSVelvetView registerDraggingDestination:(id)self];
    }

    [self.subviews makeObjectsPerformSelector:_cmd withObject:view];
}

- (void)willMoveToNSVelvetView:(NSVelvetView *)view; {
    if ([self respondsToSelector:@selector(supportedDragTypes)]) {
        [self.ancestorNSVelvetView unregisterDraggingDestination:(id)self];
    }

    [self.subviews makeObjectsPerformSelector:_cmd withObject:view];
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

    VELViewAnimationOptions lastAnimationOptions = VELViewCurrentAnimationOptions;
    NSMutableSet *lastLayersNeedingLayout = VELViewCurrentAnimationLayersNeedingLayout;

    @onExit {
        VELViewCurrentAnimationOptions = lastAnimationOptions;
        VELViewCurrentAnimationLayersNeedingLayout = lastLayersNeedingLayout;
    };

    [CATransaction begin];
    @onExit {
        [CATransaction commit];
    };

    VELViewCurrentAnimationOptions = 0;
    VELViewCurrentAnimationLayersNeedingLayout = nil;

    ++VELViewCurrentAnimationBlockDepth;
    @onExit {
        --VELViewCurrentAnimationBlockDepth;
    };

    [CATransaction setDisableActions:NO];
    [CATransaction setCompletionBlock:completionBlock];

    animations();
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations; {
    [self animateWithDuration:duration animations:animations completion:^{}];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(void))completionBlock; {
    [self animateWithDuration:duration options:0 animations:animations completion:completionBlock];
}

+ (void)animateWithDuration:(NSTimeInterval)duration options:(VELViewAnimationOptions)options animations:(void (^)(void))animations; {
    [self animateWithDuration:duration options:options animations:animations completion:^{}];
}

+ (void)animateWithDuration:(NSTimeInterval)duration options:(VELViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(void))completionBlock; {
    [CATransaction flush];

    VELViewAnimationOptions lastAnimationOptions = VELViewCurrentAnimationOptions;
    NSMutableSet *lastLayersNeedingLayout = VELViewCurrentAnimationLayersNeedingLayout;

    @onExit {
        VELViewCurrentAnimationOptions = lastAnimationOptions;
        VELViewCurrentAnimationLayersNeedingLayout = lastLayersNeedingLayout;
    };

    [CATransaction begin];
    @onExit {
        [CATransaction commit];
    };

    VELViewCurrentAnimationOptions = options;
    VELViewCurrentAnimationLayersNeedingLayout = [[NSMutableSet alloc] init];

    ++VELViewCurrentAnimationBlockDepth;
    @onExit {
        --VELViewCurrentAnimationBlockDepth;
    };

    [CATransaction setAnimationDuration:duration];
    [CATransaction setDisableActions:NO];
    [CATransaction setCompletionBlock:completionBlock];

    animations();

    NSSet *layersNeedingLayout = VELViewCurrentAnimationLayersNeedingLayout;

    // don't allow any new layers to get marked as needing layout
    VELViewCurrentAnimationLayersNeedingLayout = nil;

    [layersNeedingLayout makeObjectsPerformSelector:@selector(layoutIfNeeded)];
}

- (void)changeLayerProperties:(void (^)(void))changesBlock; {
    if (![[self class] isDefiningAnimation]) {
        [CATransaction performWithDisabledActions:changesBlock];
        return;
    }

    changesBlock();

    VELViewAnimationOptions options = VELViewCurrentAnimationOptions;

    if (options & VELViewAnimationOptionLayoutSubviews) {
        if (VELViewCurrentAnimationLayersNeedingLayout && ![VELViewCurrentAnimationLayersNeedingLayout containsObject:self.layer]) {
            [self.layer setNeedsLayout];
            [VELViewCurrentAnimationLayersNeedingLayout addObject:self.layer];
        }
    }

    if ((options & VELViewAnimationOptionLayoutSuperview) && self.layer.superlayer) {
        if (VELViewCurrentAnimationLayersNeedingLayout && ![VELViewCurrentAnimationLayersNeedingLayout containsObject:self.layer.superlayer]) {
            [self.layer.superlayer setNeedsLayout];
            [VELViewCurrentAnimationLayersNeedingLayout addObject:self.layer.superlayer];
        }
    }
}

+ (BOOL)isDefiningAnimation; {
    return VELViewCurrentAnimationBlockDepth > 0;
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

    // scale the context so that 1 point = layer.contentsScale pixels (like iOS)
    CGAffineTransform pointsToPixels = CGAffineTransformMakeScale(layer.contentsScale, layer.contentsScale);

    CGContextConcatCTM(context, pointsToPixels);

    // convert drawingRegion from _pixels_ to _points_
    drawingRegion = CGRectApplyAffineTransform(drawingRegion, CGAffineTransformInvert(pointsToPixels));

    // enable sub-pixel antialiasing (if drawing onto anything opaque)
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetAllowsFontSmoothing(context, YES);
    CGContextSetAllowsFontSubpixelPositioning(context, YES);
    CGContextSetAllowsFontSubpixelQuantization(context, YES);

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
    @onExit {
        VELViewPerformingDeepLayout = wasDeepLayout;
    };

    [self layoutSubviews];

    // only one view needs to inform all descendants of a layout at the top,
    // so we start from the view which received the initial call to this
    // method
    if (!wasDeepLayout) {
        [self.subviews enumerateObjectsUsingBlock:^(VELView *subview, NSUInteger i, BOOL *stop){
            [subview ancestorDidLayout];
        }];
    }
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
