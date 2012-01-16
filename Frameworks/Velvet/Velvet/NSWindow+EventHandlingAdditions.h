//
//  NSWindow+EventHandlingAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

@protocol VELBridgedView;

/*
 * Extensions to `NSWindow` to support dispatching events to Velvet.
 */
@interface NSWindow (EventHandlingAdditions)

/*
 * @name Event Handling
 */

/*
 * Returns the bridged view which is occupying the given point in the window, or
 * `nil` if there is no such view.
 *
 * This method will never return an `NSView`.
 *
 * @param windowPoint A point, specified in the coordinate system of the window,
 * at which to look for a view.
 */
- (id<VELBridgedView>)bridgedHitTest:(CGPoint)windowPoint;
@end
