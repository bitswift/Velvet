//
//  NSVelvetView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/NSVelvetView.h>
#import <QuartzCore/QuartzCore.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/NSVelvetHostView.h>
#import <Velvet/NSVelvetViewPrivate.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/VELNSView.h>
#import <Velvet/VELNSViewLayerDelegateProxy.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/VELView.h>
#import <Velvet/VELViewPrivate.h>
#import <objc/runtime.h>
#import "EXTScope.h"

static NSComparisonResult compareNSViewOrdering (NSView *viewA, NSView *viewB, void *context) {
    VELNSView *hostA = viewA.hostView;
    VELNSView *hostB = viewB.hostView;

    // hosted NSViews should be on top of everything else
    if (!hostA) {
        if (!hostB) {
            return NSOrderedSame;
        } else {
            return NSOrderedAscending;
        }
    } else if (!hostB) {
        return NSOrderedDescending;
    }

    VELView *ancestor = [hostA ancestorSharedWithView:(VELView *)hostB];
    NSCAssert2(ancestor, @"Velvet-hosted NSViews in the same NSVelvetView should share a Velvet ancestor: %@, %@", viewA, viewB);

    __block NSInteger orderA = -1;
    __block NSInteger orderB = -1;

    [ancestor.subviews enumerateObjectsUsingBlock:^(VELView *subview, NSUInteger index, BOOL *stop){
        if ([hostA isDescendantOfView:subview]) {
            orderA = (NSInteger)index;
        } else if ([hostB isDescendantOfView:subview]) {
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
 * The <VELNSViewLayerDelegateProxy> that is the delegate of the receiver's
 * layer.
 */
@property (nonatomic, strong, readonly) VELNSViewLayerDelegateProxy *selfLayerDelegateProxy;

/*
 * Returns any existing AppKit-created focus ring layer for the given view, or
 * `nil` if one could not be found.
 */
- (CALayer *)focusRingLayerForView:(NSView *)view;

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

// implemented by NSView
@dynamic layer;

@synthesize hostView = m_hostView;
@synthesize guestView = m_guestView;
@synthesize velvetHostView = m_velvetHostView;
@synthesize appKitHostView = m_appKitHostView;
@synthesize userInteractionEnabled = m_userInteractionEnabled;
@synthesize lastDraggingDestination = m_lastDraggingDestination;
@synthesize allDraggingDestinations = m_allDraggingDestinations;
@synthesize maskLayer = m_maskLayer;
@synthesize velvetRegisteredDragTypes = m_velvetRegisteredDragTypes;
@synthesize selfLayerDelegateProxy = m_selfLayerDelegateProxy;

- (id<VELHostView>)hostView {
    if (m_hostView)
        return m_hostView;
    else
        return self.superview.hostView;
}

- (void)setGuestView:(VELView *)view; {
    // disable implicit animations, or the layers will fade in and out
    [CATransaction performWithDisabledActions:^{
        m_guestView.hostView = nil;
        [m_guestView.layer removeFromSuperlayer];

        if ((m_guestView = view)) {
            // we need to set the frame of the view before it is added as a sublayer to the velvetHostView's layer
            m_guestView.frame = self.bounds;
            m_guestView.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

            [self.velvetHostView.layer addSublayer:m_guestView.layer];
            m_guestView.hostView = self;
            [self invalidateRestorableState];
        }
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

    m_maskLayer = [CAShapeLayer layer];

    // enable layer-backing for this view
    [self setWantsLayer:YES];

    m_velvetHostView = [[NSVelvetHostView alloc] initWithFrame:self.bounds];
    m_velvetHostView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:m_velvetHostView];

    m_appKitHostView = [[NSView alloc] initWithFrame:self.bounds];
    m_appKitHostView.autoresizesSubviews = NO;
    m_appKitHostView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [m_appKitHostView setWantsLayer:YES];
    [self addSubview:m_appKitHostView];

    // set up masking on the AppKit host view, and make ourselves the layout
    // manager, so that we'll know when new sublayers are added
    self.appKitHostView.layer.mask = self.maskLayer;
    self.appKitHostView.layer.layoutManager = self;

    // setting this up should create a proxy for self.appKitHostView as well
    m_selfLayerDelegateProxy = [VELNSViewLayerDelegateProxy layerDelegateProxyWithLayer:self.layer];

    self.guestView = [[VELView alloc] init];

    [self recalculateNSViewClipping];
}

- (void)dealloc {
    self.guestView.hostView = nil;
}

#pragma mark Layout

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
        id<VELBridgedView> hostView = view.hostView;
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

#pragma mark CALayer delegate

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    if (layer == self.layer) {
        // NSVelvetView.layer is being laid out
        return;
    }

    // appKitHostView.layer is being laid out
    //
    // this often happens in response to AppKit adding a focus ring layer, so
    // recalculate our clipping paths to take it into account
    [self recalculateNSViewClipping];
}

#pragma mark Focus Ring

- (CALayer *)focusRingLayerForView:(NSView *)view; {
    CALayer *resultSoFar = nil;

    for (CALayer *layer in self.appKitHostView.layer.sublayers) {
        // don't return the layer of the view itself
        if (layer == view.layer) {
            continue;
        }

        // if the layer doesn't wrap around this view, it's not the focus ring
        if (!CGRectContainsRect(layer.frame, view.frame)) {
            continue;
        }

        // if resultSoFar matched more tightly than this layer, consider the
        // former to be the focus ring
        if (resultSoFar && !CGRectContainsRect(resultSoFar.frame, layer.frame)) {
            continue;
        }

        resultSoFar = layer;
    }

    return resultSoFar;
}

#pragma mark Masking

- (void)recalculateNSViewOrdering; {
    [self.appKitHostView sortSubviewsUsingFunction:&compareNSViewOrdering context:NULL];
}

- (void)recalculateNSViewClipping; {
    CGMutablePathRef path = CGPathCreateMutable();

    for (NSView *view in self.appKitHostView.subviews) {
        id<VELBridgedView> hostView = view.hostView;
        if (!hostView)
            continue;

        CALayer *focusRingLayer = [self focusRingLayerForView:view];
        if (focusRingLayer) {
            id<VELBridgedView> clippingView = [hostView ancestorScrollView];

            if (clippingView) {
                // set up a mask on the focus ring that clips to any ancestor scroll views
                CAShapeLayer *maskLayer = (id)focusRingLayer.mask;
                if (![maskLayer isKindOfClass:[CAShapeLayer class]]) {
                    maskLayer = [CAShapeLayer layer];

                    focusRingLayer.mask = maskLayer;
                }

                CGRect rect = [clippingView.layer convertAndClipRect:clippingView.layer.bounds toLayer:focusRingLayer];
                if (CGRectIsNull(rect) || CGRectIsInfinite(rect)) {
                    rect = CGRectZero;
                }

                CGPathRef focusRingPath = CGPathCreateWithRect(rect, NULL);
                @onExit {
                    CGPathRelease(focusRingPath);
                };

                maskLayer.path = focusRingPath;

                CGPathAddRect(path, NULL, [focusRingLayer convertAndClipRect:rect toLayer:self.layer]);
            } else {
                focusRingLayer.mask = nil;

                CGPathAddRect(path, NULL, [focusRingLayer convertAndClipRect:focusRingLayer.bounds toLayer:self.layer]);
            }
        }

        // clip the frame of each NSView using the Velvet hierarchy
        CGRect rect = [hostView.layer convertAndClipRect:hostView.layer.bounds toLayer:self.layer];
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
    [self invalidateRestorableState];

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

#pragma mark VELHostView

- (void)ancestorDidLayout; {
    [super ancestorDidLayout];
    [self.guestView ancestorDidLayout];
}

- (id<VELBridgedView>)descendantViewAtPoint:(CGPoint)point {
    if (!CGRectContainsPoint(self.bounds, point))
        return nil;

    return [self.guestView descendantViewAtPoint:point] ?: self;
}

- (void)willMoveToNSVelvetView:(NSVelvetView *)view; {
    // despite the <VELBridgedView> contract that says we should forward this
    // message onto all subviews and our guestView, doing so could result in
    // crazy behavior, since the NSVelvetView of those views is and will remain
    // 'self' by definition
}

- (void)didMoveFromNSVelvetView:(NSVelvetView *)view; {
    // despite the <VELBridgedView> contract that says we should forward this
    // message onto all subviews and our guestView, doing so could result in
    // crazy behavior, since the NSVelvetView of those views is and will remain
    // 'self' by definition
}

#pragma mark Restoration

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];

    // Clear out the archiver's delegate
    // and keep a reference to it so we can archive the guestView
    // using default NSKeyedArchiver behavior
    NSKeyedArchiver *archiver = (id)coder;
    id delegate = [archiver delegate];
    [archiver setDelegate:nil];

    [coder encodeObject:self.guestView forKey:@"guestView"];

    [archiver setDelegate:delegate];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
    [super restoreStateWithCoder:coder];

    VELView *guestView = [coder decodeObjectForKey:@"guestView"];
    if (guestView) {
        self.guestView.subviews = nil;
        self.guestView = guestView;
        [self recalculateNSViewClipping];
    }

}

@end
