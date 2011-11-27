//
//  VELNSView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>

/**
 * A view that is responsible for displaying and handling an `NSView` within the
 * normal Velvet view hierarchy.
 */
@interface VELNSView : VELView

/**
 * @name Initialization
 */

/**
 * Initializes the receiver, setting its `NSView` property to `view`.
 *
 * The designated initializer for this class is <[VELView init]>.
 *
 * @param view The view to display in the receiver.
 */
- (id)initWithNSView:(NSView *)view;

/**
 * @name NSView Hierarchy
 */

/**
 * The view displayed by the receiver.
 */
@property (strong) NSView *NSView;
@end
