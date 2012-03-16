//
//  VELWindow.h
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

@class NSVelvetView;
@class VELView;

/**
 * An `NSWindow` automatically set up with a Velvet hierarchy.
 *
 * This class provides a couple of additional capabilities useful for Velvet
 * applications:
 *
 *  - It fixes a bug where layer tree renderers sometimes don't get re-enabled
 *  after fast user switching.
 *  - It provides a slow-motion animation mode in Debug builds, which can be
 *  activated by pressing Shift three times while the window has focus.
 */
@interface VELWindow : NSWindow

/**
 * @name Velvet Hosting
 */

/**
 * The content view of the window, hosting a Velvet hierarchy.
 *
 * This must be set to a view which is an instance of <NSVelvetView>.
 */
@property (nonatomic, strong) NSVelvetView *contentView;

/**
 * The root of the Velvet hierarchy in the receiver.
 */
@property (nonatomic, strong) VELView *rootView;

@end
