//
//  VELWindow.h
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * An `NSWindow` with support for dispatching events to `VELView` hierarchies
 * contained within. You must use an instance of this class in order for events
 * to be received correctly by Velvet.
 *
 * The `contentView` of this window must be an `NSVelvetView`.
 */
@interface VELWindow : NSWindow
@end
