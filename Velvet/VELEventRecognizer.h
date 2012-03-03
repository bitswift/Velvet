//
//  VELEventRecognizer.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VELBridgedView;

/**
 * Defines the possible states that a <VELEventRecognizer> can be in.
 */
typedef enum {
    /**
     * The event recognizer has not yet recognized its event.
     *
     * From this state, the event recognizer may move to:
     *
     *  - <VELEventRecognizerStateBegan>
     *  - <VELEventRecognizerStateFailed>
     *  - <VELEventRecognizerStateRecognized>
     *
     * This is the default state.
     */
    VELEventRecognizerStatePossible,

    /**
     * The event recognizer has recognized the beginning of a continuous event.
     *
     * From this state, the event recognizer may move to:
     *
     *  - <VELEventRecognizerStateChanged>
     *  - <VELEventRecognizerStateEnded>
     *  - <VELEventRecognizerStateCancelled>
     */
    VELEventRecognizerStateBegan,

    /**
     * A continous event already recognized has been changed.
     *
     * From this state, the event recognizer may move to:
     *
     *  - <VELEventRecognizerStateChanged> (again)
     *  - <VELEventRecognizerStateEnded>
     *  - <VELEventRecognizerStateCancelled>
     */
    VELEventRecognizerStateChanged,

    /**
     * A continous event already recognized has ended.
     *
     * From this state, the event recognizer will automatically move to
     * <VELEventRecognizerStatePossible> on the next run loop iteration.
     */
    VELEventRecognizerStateEnded,

    /**
     * A continous event already recognized has been cancelled.
     *
     * From this state, the event recognizer will automatically move to
     * <VELEventRecognizerStatePossible> on the next run loop iteration.
     */
    VELEventRecognizerStateCancelled,

    /**
     * The event recognizer failed to recognize a discrete event.
     *
     * From this state, the event recognizer will automatically move to
     * <VELEventRecognizerStatePossible> on the next run loop iteration.
     */
    VELEventRecognizerStateFailed,

    /**
     * The event recognizer has recognized a discrete event.
     *
     * From this state, the event recognizer will automatically move to
     * <VELEventRecognizerStatePossible> on the next run loop iteration.
     */
    VELEventRecognizerStateRecognized = VELEventRecognizerStateEnded
} VELEventRecognizerState;

/**
 * An abstract class representing an event recognizer, which is an object
 * similar to `UIGestureRecognizer` that can identify continuous or discrete
 * events of any kind.
 *
 * An event recognizer can be attached to any <VELBridgedView>, and will inspect
 * any `NSEvent` instances handled by the view or any of its descendants. When
 * the event recognizer identifies an `NSEvent` stream that represents its
 * higher-level event, it will transition into the appropriate
 * `VELEventRecognizerState` (setting the <state> property in the process) and
 * fire its action blocks.
 */
@interface VELEventRecognizer : NSObject

/**
 * @name Attached View
 */

/**
 * The view that the receiver is attached to.
 *
 * Setting this property will detach the receiver from its previous view and
 * attach it to the new one. If this is set to `nil`, the receiver will not be
 * attached to any view.
 *
 * @warning **Important:** The view set here will automatically retain the
 * receiver until this is set to `nil` or the view is deallocated.
 */
@property (nonatomic, weak) id<VELBridgedView> view;

/**
 * @name Recognizer State
 */

/**
 * The current state of the event recognizer.
 */
@property (nonatomic, assign, readonly) VELEventRecognizerState state;

/**
 * Whether the receiver has recognized and is currently handling its event.
 *
 * This will be `YES` if the receiver's <state> is one of the following:
 *
 *  - `VELEventRecognizerStateBegan`
 *  - `VELEventRecognizerStateChanged`
 *  - `VELEventRecognizerStateEnded`
 *  - `VELEventRecognizerStateRecognized`
 */
@property (nonatomic, getter = isActive, readonly) BOOL active;

/**
 * Whether the receiver is enabled and able to process events.
 *
 * If the receiver is currently recognizing a continuous event, setting this
 * property to `NO` will immediately set <state> to
 * `VELEventRecognizerStateCancelled` and invoke any applicable actions.
 *
 * Once set, the receiver will remain in the `VELEventRecognizerStatePossible`
 * state until re-enabled.
 */
@property (nonatomic, getter = isEnabled) BOOL enabled;

/**
 * Resets the receiver's <state> to `VELEventRecognizerStatePossible`.
 *
 * This method may be overridden by subclasses to perform any additional cleanup
 * required before being able to recognize another event.
 *
 * @warning **Important:** If <delaysEventDelivery> is `YES`, this will drop all
 * delayed events without delivering them to the receiver's <view>.
 */
- (void)reset;

/**
 * @name Information about Event Recognition
 */

/**
 * Whether the receiver recognizes continuous events.
 *
 * Continuous event recognizers transition between the following <state> values:
 *
 *  - `VELEventRecognizerStatePossible`
 *  - `VELEventRecognizerStateBegan`
 *  - `VELEventRecognizerStateChanged`
 *  - `VELEventRecognizerStateEnded`
 *  - `VELEventRecognizerStateCancelled`
 *
 * This is not mutually exclusive with <discrete> -- an event recognizer may be
 * capable of recognizing both continuous and discrete events, though it will
 * not identify both kinds simultaneously.
 *
 * The default implementation of this property returns `NO`.
 */
@property (nonatomic, getter = isContinuous, readonly) BOOL continuous;

/**
 * Whether the receiver recognizes discrete events.
 *
 * Discrete event recognizers transition between the following <state> values:
 *
 *  - `VELEventRecognizerStatePossible`
 *  - `VELEventRecognizerStateFailed`
 *  - `VELEventRecognizerStateRecognized`
 *
 * This is not mutually exclusive with <continuous> -- an event recognizer may
 * be capable of recognizing both continuous and discrete events, though it will
 * not identify both kinds simultaneously.
 *
 * The default implementation of this property returns `NO`.
 */
@property (nonatomic, getter = isDiscrete, readonly) BOOL discrete;

/**
 * @name Recognizer Dependencies
 */

/**
 * Contains other <VELEventRecognizer> instances that are required to fail
 * before the receiver should recognize its event.
 *
 * This is used to create dependencies where the receiver can only succeed if
 * the specified event recognizers fail to recognize their events. In other
 * words, the receiver cannot succeed if any one of the specified recognizers
 * succeed first.
 *
 * The default value for this property is `nil`.
 */
@property (nonatomic, copy) NSSet *recognizersRequiredToFail;

/**
 * @name Controlling Event Delivery
 */

/**
 * Whether the receiver should delay `NSEvent` delivery to its <view> until it
 * has recognized or failed to recognize its event.
 *
 * In other words, if this is set to `YES`, the receiver will capture `NSEvent`
 * objects meant for its <view> while simultaneously trying to recognize its
 * event. If the event is successfully recognized, the `NSEvent` objects are
 * never delivered to the view. If the event fails to be recognized, then the
 * `NSEvent` objects are immediately sent to the view in the order they arrived.
 *
 * The default value for this property is `NO`.
 */
@property (nonatomic, assign) BOOL delaysEventDelivery;

/**
 * @name Action Blocks
 */

/**
 * Registers a block to be called whenever the receiver's <state> changes.
 *
 * This method returns an object which can later be used with <removeAction:> to
 * de-register the action. The object does not need to be retained, and can be
 * discarded if removal will not be needed.
 *
 * @param block A block to invoke when the receiver's <state> changes. The block
 * will be passed the receiver when invoked.
 */
- (id)addActionUsingBlock:(void (^)(VELEventRecognizer *))block;

/**
 * De-registers a block previously added with <addActionUsingBlock:>.
 *
 * @param action An object returned from <addActionUsingBlock:> corresponding to
 * the block that you wish to de-register.
 */
- (void)removeAction:(id)action;

@end
