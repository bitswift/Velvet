//
//  NSWindow+EventHandlingAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

@class VELView;

/*
 * Extensions to `NSWindow` to support dispatching events to Velvet.
 */
@interface NSWindow (EventHandlingAdditions)

/*
 * @name Event Handling
 */

/*
 * Returns the <VELView> which is occupying the given point in the window, or
 * `nil` if there is no such view.
 *
 * @param windowPoint A point, specified in the coordinate system of the window,
 * at which to look for a view.
 */
- (VELView *)bridgedHitTest:(CGPoint)windowPoint;

/*
 * Hit tests for a <VELView> in the region identified by the given event,
 * returning any <VELView> that is found, or `nil` if no Velvet view is found.
 *
 * @param event The mouse-related event which occurred.
 */
- (VELView *)velvetViewForMouseDownEvent:(NSEvent *)event;

/*
 * Returns the most descendant Velvet scroll view in the region identified by
 * the given event, or `nil` if no Velvet scroll view exists at the event's
 * location.
 *
 * @param event The scroll wheel event which occurred.
 */
- (VELView *)velvetViewForScrollEvent:(NSEvent *)event;
@end
