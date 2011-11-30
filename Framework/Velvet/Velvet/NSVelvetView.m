//
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSVelvetView.h>
#import <Velvet/CALayer+GeometryAdditions.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/NSVelvetHostView.h>
#import <Velvet/NSView+VELNSViewAdditions.h>
#import <Velvet/NSViewClipRenderer.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/VELContext.h>
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
@property (nonatomic, strong) NSView *velvetHostView;
@property (nonatomic, readwrite, strong) VELContext *context;
@property (nonatomic, assign, getter = isUserInteractionEnabled) BOOL userInteractionEnabled;

/*
 * Holds a reference to the descendant destination view of the current dragging operation
 *
 * @param lastDraggingDestination The receiver of the last propogated dragging event.
 */
@property (nonatomic, weak) id <VELBridgedView> lastDraggingDestination;

/*
 * Collects all of the views messaged during the current dragging session. For consistency
 * with normal `NSDraggingDestination` behavior, all views which have recieved events this
 * session (or would have done if they implemented the respective methods) are messaged
 * with <draggingEnded:> when the session ends.
 */
@property (nonatomic, strong) NSMutableSet *allDraggingDestinations;

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
@end

@implementation NSVelvetView

#pragma mark Properties

@synthesize context = m_context;
@synthesize rootView = m_rootView;
@synthesize velvetHostView = m_velvetHostView;
@synthesize userInteractionEnabled = m_userInteractionEnabled;
@synthesize lastDraggingDestination = m_lastDraggingDestination;
@synthesize allDraggingDestinations = m_allDraggingDestinations;

- (void)setRootView:(VELView *)view; {
    // disable implicit animations, or the layers will fade in and out
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    [m_rootView.layer removeFromSuperlayer];
    [self.velvetHostView.layer addSublayer:view.layer];

    m_rootView.hostView = nil;
    view.hostView = self;

    m_rootView = view;

    [CATransaction commit];
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
    self.context = [[VELContext alloc] init];
    self.userInteractionEnabled = YES;

    // enable layer-backing for this view
    [self setWantsLayer:YES];
    self.layer.layoutManager = self;

    self.velvetHostView = [[NSVelvetHostView alloc] initWithFrame:self.bounds];
    self.velvetHostView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:self.velvetHostView];

    self.rootView = [[VELView alloc] init];
    self.rootView.frame = self.bounds;

    [self
        registerForDraggedTypes:[NSArray
            arrayWithObjects: NSColorPboardType, NSFilenamesPboardType, NSPasteboardTypePDF, nil]];
}

#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize; {
    // always resize the root view to fill this view
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.rootView.layer.frame = self.velvetHostView.layer.frame = self.bounds;
    [CATransaction commit];
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
    [self.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSView *view, NSUInteger index, BOOL *stop){
        VELNSView *hostView = view.hostView;
        if (hostView) {
            CGRect bounds = hostView.layer.bounds;
            CGRect clippedBounds = [hostView.layer convertAndClipRect:bounds toLayer:view.layer];
            
            CGPoint subviewPoint = [view convertPoint:point fromView:self];
            if (!CGRectContainsPoint(clippedBounds, subviewPoint)) {
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

- (void)didAddSubview:(NSView *)subview {
    [self sortSubviewsUsingFunction:&compareNSViewOrdering context:NULL];
}

- (id<VELBridgedView>)descendantViewAtPoint:(CGPoint)point {
    if (!CGRectContainsPoint(self.bounds, point))
        return nil;
    return [self.rootView descendantViewAtPoint:point] ?: self;
}
#pragma mark CALayer delegate

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    if ([[NSVelvetView superclass] instancesRespondToSelector:_cmd]) {
        [super performSelector:@selector(layoutSublayersOfLayer:) withObject:layer];
    }

    NSArray *existingSublayers = [layer.sublayers copy];

    [CATransaction performWithDisabledActions:^{
        for (CALayer *sublayer in existingSublayers) {
            if (sublayer.delegate || sublayer == self.velvetHostView.layer) {
                // this is ours
                continue;
            }

            // this is probably a focus ring -- try to find the view that it
            // belongs to so we can clip it
            [self replaceFocusRingLayer:sublayer];
        }
    }];
}

- (void)replaceFocusRingLayer:(CALayer *)layer; {
    for (NSView *view in self.subviews) {
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

    VELFocusRingLayer *focusRingLayer = [[VELFocusRingLayer alloc] initWithOriginalLayer:layer hostView:hostView];
    [self.layer addSublayer:focusRingLayer];

    focusRingLayer.frame = layer.frame;
    hostView.focusRingLayer = focusRingLayer;
}

#pragma mark Dragging

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    CGPoint draggedPoint = [self convertFromWindowPoint:[sender draggingLocation]];
    id <VELBridgedView> view = [self descendantViewAtPoint:draggedPoint];

    if (view == self)
        return NSDragOperationNone;

    self.lastDraggingDestination = view;

    if ([view respondsToSelector:@selector(draggingEntered:)]) {
        return [view draggingEntered:sender];
    }

    if (!self.allDraggingDestinations) self.allDraggingDestinations = [NSMutableSet set];
    if (view) [self.allDraggingDestinations addObject:view];

    return NSDragOperationNone;

}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    CGPoint draggedPoint = [self convertFromWindowPoint:[sender draggingLocation]];
    id <VELBridgedView> view = [self descendantViewAtPoint:draggedPoint];

    if (self.lastDraggingDestination != view) {
        if ([self.lastDraggingDestination respondsToSelector:@selector(draggingExited:)]) {
            [self.lastDraggingDestination draggingExited:sender];
        }

        if (view && view != self) {
            self.lastDraggingDestination = view;
            [self.allDraggingDestinations addObject:view];
            if ([view respondsToSelector:@selector(draggingEntered:)]) {
                return [view draggingEntered:sender];
            }
        } else {
            self.lastDraggingDestination = nil;
        }
    } else if (view != self && [view respondsToSelector:@selector(draggingUpdated:)]) {
        return [view draggingUpdated:sender];
    }

    return NSDragOperationNone;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    for (id <VELBridgedView> view in self.allDraggingDestinations) {
        if ([view respondsToSelector:@selector(draggingEnded:)]) {
            [view draggingEnded:sender];
        }
    }

    self.allDraggingDestinations = nil;
    self.lastDraggingDestination = nil;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    id <VELBridgedView> view = self.lastDraggingDestination;

    if (view != self && [view respondsToSelector:@selector(draggingExited:)])
        [view draggingExited:sender];

    self.lastDraggingDestination = nil;
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
    id <VELBridgedView> view = self.lastDraggingDestination;

    if (view != self && [view respondsToSelector:@selector(prepareForDragOperation:)]) {
        return [view prepareForDragOperation:sender];
    }

    return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
    id <VELBridgedView> view = self.lastDraggingDestination;

    if (view != self && [view respondsToSelector:@selector(performDragOperation:)]) {
        return [view performDragOperation:sender];
    }

    return NO;
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender {
    id <VELBridgedView> view = self.lastDraggingDestination;

    if (view != self && [view respondsToSelector:@selector(concludeDragOperation:)]) {
        [view concludeDragOperation:sender];
    }
}

- (void)updateDraggingItemsForDrag:(id <NSDraggingInfo>)sender {
    id <VELBridgedView> view = self.lastDraggingDestination;

    if (view != self && [view respondsToSelector:@selector(updateDraggingItemsForDrag:)]) {
        [view updateDraggingItemsForDrag:sender];
    }
}
@end
