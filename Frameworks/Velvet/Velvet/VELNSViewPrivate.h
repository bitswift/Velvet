//
//  VELNSViewPrivate.h
//  Velvet
//
//  Created by James Lawton on 23.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELNSView.h>

@class VELFocusRingLayer;

/*
 * Private functionality of <VELNSView> that needs to be exposed to other parts
 * of the framework.
 */
@interface VELNSView (Private)
/*
 * Whether the receiver should render its `NSView`.
 *
 * If set to `NO`, the `NSView` is rendered once and cached into the receiver's layer. This is typically used for animations.
 */
@property (nonatomic, assign) BOOL rendersContainedView;

/*
 * The frame that the receiver's `NSView` should have at the time of call.
 *
 * This is used by <synchronizeNSViewGeometry> to keep the `NSView` attached to
 * its Velvet view.
 *
 * If the receiver has no host view, the value is undefined.
 */
@property (readonly) CGRect NSViewFrame;

/*
 * A layer holding a focus ring for this view, if one exists.
 *
 * This layer may not be a descendant of the receiver's layer.
 */
@property (nonatomic, strong) VELFocusRingLayer *focusRingLayer;

/*
 * This will synchronize the geometry of the receiver's `NSView` with that of
 * the receiver, ensuring that the `NSView` is laid out correctly on screen.
 */
- (void)synchronizeNSViewGeometry;
@end
