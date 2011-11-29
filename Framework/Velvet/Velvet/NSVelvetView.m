//
//  NSVelvetView.m
//  Velvet
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


#pragma mark NSView hierarchy

- (void)didAddSubview:(NSView *)subview {
    [self sortSubviewsUsingFunction:&compareNSViewOrdering context:NULL];
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

    if ([view respondsToSelector:@selector(draggingEntered:)])
        return [view draggingEntered:sender];
    else
        return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
    return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
    return YES;
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender {
    NSLog(@"Dragged sender %@", sender);
    NSPasteboard *draggingPasteboard = [sender draggingPasteboard];
    NSLog(@"Data is %@", [draggingPasteboard pasteboardItems]);
}
@end
