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
 * The view displayed by the receiver.
 */
@property (strong) NSView *NSView;

/**
 * Initializes the receiver, setting its `NSView` property to `view`.
 *
 * @note The designated initializer for this class is `init`.
 */
- (id)initWithNSView:(NSView *)view;
@end
