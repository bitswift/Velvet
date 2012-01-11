//
//  NSVelvetView+Private.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSVelvetView.h>
#import <Velvet/VELDraggingDestination.h>

/*
 * Private functionality of <NSVelvetView> that needs to be exposed to other parts of
 * the framework.
 */
@interface NSVelvetView (Private)
/*
 * Whether user interaction (i.e., event handling) is enabled.
 *
 * This can be set to `NO` to effectively remove the `NSView` hierarchy from
 * consideration for events. Setting this property to `NO` does not affect event
 * handling for any Velvet views (since they are directly sent events from
 * <VELWindow>).
 *
 * The default value is `YES`.
 */
@property (nonatomic, assign, getter = isUserInteractionEnabled) BOOL userInteractionEnabled;

/*
 * The layer-backed view which actually holds the AppKit hierarchy.
 */
@property (nonatomic, readonly, strong) NSView *appKitHostView;

/*
 * Registers the given object to receive drag-and-drop events from the receiver.
 *
 * Drag-and-drop events may not be propagated to <VELView> instances unless they
 * are registered using this method.
 *
 * To later unregister the given object, use <unregisterDraggingDestination:>.
 *
 * @param destination The object which should receive drag-and-drop events. This
 * argument should be `nil`.
 */
- (void)registerDraggingDestination:(id<VELDraggingDestination>)destination;

/*
 * Unregisters a dragging destination previously added with
 * <registerDraggingDestination:>.
 *
 * Calls to this method must be balanced with calls that were made to
 * <registerDraggingDestination:>.
 *
 * @param destination An object previously passed to
 * <registerDraggingDestination:>.
 */
- (void)unregisterDraggingDestination:(id<VELDraggingDestination>)destination;

/*
 * Informs the receiver that the clipping of a <VELNSView> it is hosting has
 * changed, and asks it to update clipping paths accordingly.
 */
- (void)recalculateNSViewClipping;
@end
