//
//  VELControl.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 30.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELView.h>

/**
 * Defines events that a <VELControl> will send.
 */
typedef enum {
    /**
     * The control was clicked.
     *
     * A click is defined as a mouse down followed by a mouse up, with both
     * mouse events landing inside the frame of the control.
     */
    VELControlEventClicked = (1 << 0),

    /**
     * The control was double-clicked.
     *
     * This event is sent when two clicks occur in quick succession, after any
     * <VELControlEventClicked> actions have been invoked.
     */
    VELControlEventDoubleClicked = (1 << 1),

    /**
     * The value of the control has changed.
     *
     * The concept of the control's "value" is specific to the type of control
     * being used. <VELControl> itself does not trigger this event.
     */
    VELControlEventValueChanged = (1 << 2),

    /**
     * The control was selected.
     *
     * This event occurs when <[VELControl selected]> is set to `YES`.
     */
    VELControlEventSelected = (1 << 3),

    /**
     * The control was deselected.
     *
     * This event occurs when <[VELControl selected]> is set to `NO`.
     */
    VELControlEventDeselected = (1 << 4),

    /**
     * A range of event values available for application use.
     */
    VELControlEventApplicationReserved = 0xFF000000,

    /**
     * All events, including system events.
     */
    VELControlAllEvents = 0xFFFFFFFF
} VELControlEventMask;

/**
 * A control that can receive click events, similar to `UIControl`.
 */
@interface VELControl : VELView

/**
 * @name Control States
 */

/**
 * A boolean value that determines the receiver’s selected state.
 *
 * The default value for this property is `NO`.
 */
@property (nonatomic, assign, getter = isSelected) BOOL selected;

/**
 * @name Event Dispatch
 */

/**
 * Registers a block to be called whenever the given events are triggered.
 *
 * This method returns an object which can later be used with
 * <removeAction:forControlEvents:> to de-register the action. The object does
 * not need to be retained, and can be discarded if removal will not be needed.
 *
 * @param eventMask The events for which to trigger `actionBlock`.
 * @param actionBlock A block to invoke when any of the given events are
 * triggered. The block should take a single `NSEvent` argument, which is the
 * underlying system event that is triggering the action.
 */
- (id)addActionForControlEvents:(VELControlEventMask)eventMask usingBlock:(void (^)(NSEvent *))actionBlock;

/**
 * De-registers a block or blocks previously added with
 * <addActionForControlEvents:usingBlock:> from a set of events.
 *
 * Trying to remove an action from events for which it is not registered will
 * have no effect.
 *
 * @param action An object returned from <addActionForControlEvents:usingBlock:>
 * corresponding to the block that you wish to de-register. If this argument is
 * `nil`, all blocks corresponding to the `eventMask` are de-registered.
 * @param eventMask The events to stop listening for. Use `VELControlAllEvents`
 * to stop listening for any events.
 */
- (void)removeAction:(id)action forControlEvents:(VELControlEventMask)eventMask;

/**
 * Sends action messages for the given event mask, passing a `nil` event to each
 * action block.
 *
 * @param eventMask A bitmask specifying which events to send actions for.
 */
- (void)sendActionsForControlEvents:(VELControlEventMask)eventMask;

/**
 * Sends action messages for the given event mask, passing the given event to
 * each action block.
 *
 * @param eventMask A bitmask specifying which events to send actions for.
 * @param event The underlying event that is causing actions to be invoked.
 */
- (void)sendActionsForControlEvents:(VELControlEventMask)eventMask event:(NSEvent *)event;
@end
