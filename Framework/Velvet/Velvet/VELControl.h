//
//  VELControl.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 30.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>

/**
 * Defines events that a <VELControl> will send.
 */
typedef enum {
    /**
     * The control was clicked.
     */
    VELControlEventClicked = (1 << 0),

    /**
     * The control was double-clicked.
     *
     * This event is always sent after two <VELControlEventClicked> events (one
     * for each click).
     */
    VELControlEventDoubleClicked = (1 << 1),

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
 * @name Setting and Getting Control States
 */

/**
 * A Boolean value that determines the receiver’s selected state.
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
 * @param actionBlock A block to invoke when any of the given events are triggered.
 */
- (id)addActionForControlEvents:(VELControlEventMask)eventMask usingBlock:(void (^)(void))actionBlock;

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
 * Sends action messages for the given events.
 *
 * @param eventMask A bitmask specifying which events to send actions for.
 */
- (void)sendActionsForControlEvents:(VELControlEventMask)eventMask;
@end
