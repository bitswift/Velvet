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

/*
 * Hit tests for a bridged view in the region identified by the given event,
 * returning any non-AppKit view that is found.
 *
 * This method will never return an `NSView`.
 *
 * @param event The mouse-related event which occurred.
 */
- (id<VELBridgedView>)bridgedViewForMouseDownEvent:(NSEvent *)event;

/*
 * Returns the most descendant non-AppKit scroll view in the region identified
 * by the given event, or `nil` if no such scroll view exists at the event's
 * location.
 *
 * This method will never return an `NSView`.
 *
 * @param event The scroll wheel event which occurred.
 */
- (id<VELBridgedView>)bridgedViewForScrollEvent:(NSEvent *)event;
@end
