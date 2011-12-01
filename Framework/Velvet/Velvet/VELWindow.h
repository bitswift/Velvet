//
//  VELWindow.h
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>

@class VELView;

/**
 * An `NSWindow` with support for dispatching events to `VELView` hierarchies
 * contained within. You must use an instance of this class in order for events
 * to be received correctly by Velvet.
 *
 * The window is automatically set up with an `NSVelvetView` for its
 * `contentView`. You must not change its content view to be any other class.
 */
@interface VELWindow : NSWindow
/**
 * The root of the Velvet hierarchy in the receiver.
 */
@property (nonatomic, readonly) VELView *rootView;
@end
