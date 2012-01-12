//
//  NSVelvetView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/NSVelvetView.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/NSVelvetHostView.h>
#import <Velvet/NSVelvetViewPrivate.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/VELFocusRingLayer.h>
#import <Velvet/VELNSView.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/VELView.h>
#import <Velvet/VELViewPrivate.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static NSComparisonResult compareNSViewOrdering (NSView *viewA, NSView *viewB, void *context) {
    VELView *velvetA = viewA.hostView;
    VELView *velvetB = viewB.hostView;

    // Velvet-hosted NSViews should be on top of everything else
    if (!velvetA) {
        if (!velvetB) {
            return NSOrderedSame;
        } else {
            return NSOrderedAscending;
        }
    } else if (!velvetB) {
        return NSOrderedDescending;
    }

    VELView *ancestor = [velvetA ancestorSharedWithView:velvetB];
    NSCAssert2(ancestor, @"Velvet-hosted NSViews in the same NSVelvetView should share a Velvet ancestor: %@, %@", viewA, viewB);

    __block NSInteger orderA = -1;
    __block NSInteger orderB = -1;

    [ancestor.subviews enumerateObjectsUsingBlock:^(VELView *subview, NSUInteger index, BOOL *stop){
        if ([velvetA isDescendantOfView:subview]) {
            orderA = (NSInteger)index;
        } else if ([velvetB isDescendantOfView:subview]) {
            orderB = (NSInteger)index;
        }

        if (orderA >= 0 && orderB >= 0) {
            *stop = YES;
        }
    }];

    if (orderA < orderB) {
        return NSOrderedAscending;
    } else if (orderA > orderB) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

@interface NSVelvetView ()
@property (nonatomic, readonly, strong) NSView *appKitHostView;

/*
 * Documented in <NSVelvetViewPrivate>.
 */
@property (nonatomic, assign, getter = isUserInteractionEnabled) BOOL userInteractionEnabled;

/*
 * The layer-hosted view which actually holds the Velvet hierarchy.
 */
@property (nonatomic, readonly, strong) NSVelvetHostView *velvetHostView;

/*
 * Holds a reference to the descendant destination view of the current dragging operation
 *
 * @param lastDraggingDestination The receiver of the last propogated dragging event.
 */
@property (nonatomic, weak) id<VELDraggingDestination> lastDraggingDestination;

/*
 * Collects all of the views messaged during the current dragging session. For consistency
 * with normal `NSDraggingDestination` behavior, all views which have recieved events this
 * session (or would have done if they implemented the respective methods) are messaged
 * with <draggingEnded:> when the session ends.
 */
@property (nonatomic, strong) NSMutableSet *allDraggingDestinations;

/*
 * A counted set of the UTIs registered for drag-and-drop by Velvet views.
 */
@property (nonatomic, strong) NSCountedSet *velvetRegisteredDragTypes;

/*
 * A layer used to mask the rendering of `NSView`-owned layers added to the
 * receiver.
 *
 * This masking will keep the rendering of a given `NSView` consistent with the
 * clipping its <VELNSView> would have in the Velvet hierarchy.
 */
@property (nonatomic, strong) CAShapeLayer *maskLayer;

/*
 * Replaces a focus ring layer provided by AppKit with one of our own to
 * properly handle clipping.
 *
 * @param layer The focus ring layer installed by AppKit.
 */
- (void)replaceFocusRingLayer:(CALayer *)layer;

/*
 * Attaches a focus ring to a given <VELNSView>, synchronizing their geometry.
 *
 * The focus ring will clip to the superview of `hostView`.
 *
 * @param hostView The view which has focus.
 * @param layer The AppKit-installed layer which is currently rendering a focus
 * ring.
 */
- (void)attachFocusRingLayerToView:(VELNSView *)hostView replacingLayer:(CALayer *)layer;

/*
 * Configures all the necessary properties on the receiver. This is outside of
 * an initializer because \c NSView has no true designated initializer.
 */
- (void)setUp;

/*
 * If a <VELView> exists at the location of the given drag-and-drop operation
 * and supports any of the types provided on the drag-and-drop pasteboard, this
 * returns that <VELView>.
 *
 * If the most descendant view does not support the drag-and-drop, all of its
 * superviews are checked as well, and the first superview that does support it
 * (if any) is returned.
 *
 * @param draggingInfo Information about the drag-and-drop operation in
 * progress.
 */
- (VELView<VELDraggingDestination> *)deepestViewSupportingDraggingInfo:(id<NSDraggingInfo>)draggingInfo;
@end

@implementation NSVelvetView

#pragma mark Properties

@synthesize rootView = m_rootView;
@synthesize velvetHostView = m_velvetHostView;
@synthesize appKitHostView = m_appKitHostView;
@synthesize userInteractionEnabled = m_userInteractionEnabled;
@synthesize lastDraggingDestination = m_lastDraggingDestination;
@synthesize allDraggingDestinations = m_allDraggingDestinations;
@synthesize maskLayer = m_maskLayer;
@synthesize velvetRegisteredDragTypes = m_velvetRegisteredDragTypes;

- (void)setRootView:(VELView *)view; {
    // disable implicit animations, or the layers will fade in and out
    [CATransaction performWithDisabledActions:^{

        // we need to set the frame of the view before it is added as a sublayer to the velvetHostView's layer
        view.frame = self.bounds;

        [m_rootView.layer removeFromSuperlayer];
        [self.velvetHostView.layer addSublayer:view.layer];

        m_rootView.hostView = nil;
        m_rootView = view;
        view.hostView = self;
    }];
}

#pragma mark Lifecycle

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self)
        return nil;

    [self setUp];
    return self;
}

- (id)initWithFrame:(NSRect)frame; {
    self = [super initWithFrame:frame];
    if (!self)
        return nil;

    [self setUp];
    return self;
}

- (void)setUp; {
    self.userInteractionEnabled = YES;

    m_maskLayer = [[CAShapeLayer alloc] init];

    // enable layer-backing for this view
    [self setWantsLayer:YES];

    m_velvetHostView = [[NSVelvetHostView alloc] initWithFrame:self.bounds];
    [self addSubview:m_velvetHostView];

    m_appKitHostView = [[NSView alloc] initWithFrame:self.bounds];
    m_appKitHostView.autoresizesSubviews = NO;
    [m_appKitHostView setWantsLayer:YES];
    [self addSubview:m_appKitHostView];

    // set up masking on the AppKit host view, and make ourselves the layout
    // manager, so that we'll know when new sublayers are added
    self.appKitHostView.layer.mask = self.maskLayer;
    self.appKitHostView.layer.layoutManager = self;

    self.rootView = [[VELView alloc] init];

    [self recalculateNSViewClipping];
}

#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize; {
    // always resize the root view to fill this view
    [CATransaction performWithDisabledActions:^{
        self.velvetHostView.frame = self.bounds;
        self.appKitHostView.frame = self.bounds;

        self.rootView.layer.frame = self.bounds;
    }];
}

- (NSView *)hitTest:(NSPoint)point {
    if (!self.userInteractionEnabled)
        return nil;

    // convert point into our coordinate system, so it's ready to go for all
    // subviews (which expect it in their superview's coordinate system)
    point = [self convertPoint:point fromView:self.superview];

    __block NSView *result = self;

    // we need to avoid hitting any NSViews that are clipped by their
    // corresponding Velvet views
    [self.appKitHostView.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSView *view, NSUInteger index, BOOL *stop){
        VELNSView *hostView = view.hostView;
        if (hostView) {
            CGRect bounds = hostView.layer.bounds;
            CGRect clippedBounds = [hostView.layer convertAndClipRect:bounds toLayer:self.layer];

            if (!CGRectContainsPoint(clippedBounds, point)) {
                // skip this view
                return;
            }
        }

        NSView *hitTestedView = [view hitTest:point];
        if (hitTestedView) {
            result = hitTestedView;
            *stop = YES;
        }
    }];

    return result;
}


#pragma mark NSView hierarchy

- (id<VELBridgedView>)descendantViewAtPoint:(CGPoint)point {
    if (!CGRectContainsPoint(self.bounds, point))
        return nil;

    return [self.rootView descendantViewAtPoint:point] ?: self;
}

#pragma mark CALayer delegate

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    // TODO: factor this out into a separate class, so that the layout managers
    // for the NSVelvetView and the appKitHostView are not confused
    if (layer == self.layer) {
        return;
    }

    [self.appKitHostView sortSubviewsUsingFunction:&compareNSViewOrdering context:NULL];

    NSArray *existingSublayers = [layer.sublayers copy];

    [CATransaction performWithDisabledActions:^{
        for (CALayer *sublayer in existingSublayers) {
            if (sublayer.delegate) {
                // this is ours
                continue;
            } else if ([sublayer isKindOfClass:[VELFocusRingLayer class]]) {
                VELFocusRingLayer *focusRingLayer = (id)sublayer;

                // if the original focus ring was removed...
                if ([existingSublayers indexOfObjectIdenticalTo:focusRingLayer.originalLayer] == NSNotFound) {
                    // remove ours as well
                    [focusRingLayer removeFromSuperlayer];
                }

                continue;
            }

            // this is probably a focus ring -- try to find the view that it
            // belongs to so we can clip it
            [self replaceFocusRingLayer:sublayer];
        }
    }];
}

- (void)replaceFocusRingLayer:(CALayer *)layer; {
    for (NSView *view in self.appKitHostView.subviews) {
        // if the focus ring layer wraps around this view, it's probably the
        // ring for this view
        // TODO: match the tightest rectangle around views?
        if (CGRectContainsRect(layer.frame, view.frame)) {
            VELNSView *hostView = view.hostView;
            if (hostView) {
                [self attachFocusRingLayerToView:hostView replacingLayer:layer];
                break;
            }
        }
    }
}

- (void)attachFocusRingLayerToView:(VELNSView *)hostView replacingLayer:(CALayer *)layer; {
    NSAssert1(hostView.superview, @"%@ should have a superview if its NSView is in the NSVelvetView", hostView);

    [hostView.focusRingLayer removeFromSuperlayer];

    VELFocusRingLayer *focusRingLayer = [[VELFocusRingLayer alloc] initWithOriginalLayer:layer hostView:hostView];

    // keep the focus ring at the top level (i.e., not in the appKitHostView),
    // so that it doesn't get masked normally
    [self.layer addSublayer:focusRingLayer];

    focusRingLayer.frame = layer.frame;
    hostView.focusRingLayer = focusRingLayer;
}

#pragma mark Masking

- (void)recalculateNSViewClipping; {
    CGMutablePathRef path = CGPathCreateMutable();

    for (NSView *view in self.appKitHostView.subviews) {
        VELNSView *hostView = view.hostView;
        if (!hostView)
            continue;

        // clip the frame of each NSView using the Velvet hierarchy
        CGRect rect = [hostView.layer convertAndClipRect:hostView.bounds toLayer:self.layer];
        if (CGRectIsNull(rect) || CGRectIsInfinite(rect))
            continue;

        CGPathAddRect(path, NULL, rect);
    }

    // mask them all at once (so fast!)
    self.maskLayer.path = path;
    CGPathRelease(path);
}

#pragma mark Dragging

- (void)registerDraggingDestination:(id<VELDraggingDestination>)destination; {
    if (!self.velvetRegisteredDragTypes)
        self.velvetRegisteredDragTypes = [[NSCountedSet alloc] init];

    [self.velvetRegisteredDragTypes addObjectsFromArray:[destination supportedDragTypes]];

    [self unregisterDraggedTypes];
    [self registerForDraggedTypes:[self.velvetRegisteredDragTypes allObjects]];
}

- (void)unregisterDraggingDestination:(id<VELDraggingDestination>)destination; {
    for (NSString *type in [destination supportedDragTypes]) {
        [self.velvetRegisteredDragTypes removeObject:type];
    }

    [self unregisterDraggedTypes];

    if ([self.velvetRegisteredDragTypes count]) {
        [self registerForDraggedTypes:[self.velvetRegisteredDragTypes allObjects]];
    } else {
        self.velvetRegisteredDragTypes = nil;
    }
}

- (VELView<VELDraggingDestination> *)deepestViewSupportingDraggingInfo:(id<NSDraggingInfo>)draggingInfo; {
    CGPoint draggedPoint = [self convertFromWindowPoint:[draggingInfo draggingLocation]];
    NSArray *draggedTypes = [[draggingInfo draggingPasteboard] types];

    id view = [self descendantViewAtPoint:draggedPoint];
    if (![view isKindOfClass:[VELView class]])
        return nil;

    BOOL (^viewSupportsDrag)(id) = ^(id testView){
        if (![testView conformsToProtocol:@protocol(VELDraggingDestination)])
            return NO;

        for (NSString *supportedType in [testView supportedDragTypes]) {
            if ([draggedTypes containsObject:supportedType])
                return YES;
        }

        return NO;
    };

    // find the first superview that supports drag-and-drop (or use this view if
    // it does)
    while (!viewSupportsDrag(view)) {
        view = [view superview];

        if (!view)
            return nil;
    }

    return view;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    id<VELDraggingDestination> view = [self deepestViewSupportingDraggingInfo:sender];
    if (!view)
        return NSDragOperationNone;

    self.lastDraggingDestination = view;

    if (!self.allDraggingDestinations)
        self.allDraggingDestinations = [NSMutableSet set];

    if (view) {
        [self.allDraggingDestinations addObject:view];

        if ([view respondsToSelector:@selector(draggingEntered:)]) {
            return [view draggingEntered:sender];
        }
    }

    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    id<VELDraggingDestination> view = [self deepestViewSupportingDraggingInfo:sender];

    if (self.lastDraggingDestination != view) {
        if ([self.lastDraggingDestination respondsToSelector:@selector(draggingExited:)]) {
            [self.lastDraggingDestination draggingExited:sender];
        }

        if (view) {
            self.lastDraggingDestination = view;
            [self.allDraggingDestinations addObject:view];

            if ([view respondsToSelector:@selector(draggingEntered:)]) {
                return [view draggingEntered:sender];
            }
        } else {
            self.lastDraggingDestination = nil;
        }
    } else if ([view respondsToSelector:@selector(draggingUpdated:)]) {
        return [view draggingUpdated:sender];
    }

    return [super draggingUpdated:sender];
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    for (id<VELDraggingDestination> view in self.allDraggingDestinations) {
        if ([view respondsToSelector:@selector(draggingEnded:)]) {
            [view draggingEnded:sender];
        }
    }

    self.allDraggingDestinations = nil;
    self.lastDraggingDestination = nil;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    id<VELDraggingDestination> view = self.lastDraggingDestination;

    if ([view respondsToSelector:@selector(draggingExited:)])
        [view draggingExited:sender];

    self.lastDraggingDestination = nil;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    id<VELDraggingDestination> view = self.lastDraggingDestination;

    if ([view respondsToSelector:@selector(prepareForDragOperation:)]) {
        return [view prepareForDragOperation:sender];
    }

    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    id<VELDraggingDestination> view = self.lastDraggingDestination;

    if ([view respondsToSelector:@selector(performDragOperation:)]) {
        return [view performDragOperation:sender];
    }

    return NO;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
    id<VELDraggingDestination> view = self.lastDraggingDestination;

    if ([view respondsToSelector:@selector(concludeDragOperation:)]) {
        [view concludeDragOperation:sender];
    }
}

- (void)updateDraggingItemsForDrag:(id<NSDraggingInfo>)sender {
    id<VELDraggingDestination> view = self.lastDraggingDestination;

    if ([view respondsToSelector:@selector(updateDraggingItemsForDrag:)]) {
        [view updateDraggingItemsForDrag:sender];
    }
}
@end
