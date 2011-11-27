//
//  VELNSViewPrivate.h
//  Velvet
//
//  Created by James Lawton on 23.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELNSView.h>

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
 * This will synchronize the geometry of the receiver's `NSView` with that of
 * the receiver, ensuring that the `NSView` is laid out correctly on screen.
 */
- (void)synchronizeNSViewGeometry;
@end
