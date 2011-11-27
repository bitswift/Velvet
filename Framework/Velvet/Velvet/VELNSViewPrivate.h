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
@end
