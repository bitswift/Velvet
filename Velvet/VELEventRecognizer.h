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
     *  - <VELEventRecognizerStatePossible> (again)
     *  - <VELEventRecognizerStateBegan>
     *  - <VELEventRecognizerStateFailed>
     *  - <VELEventRecognizerStateRecognized>
     *
     * This is the default state.
     */
    VELEventRecognizerStatePossible = 0,

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
     * <VELEventRecognizerStatePossible> after invoking its action blocks.
     */
    VELEventRecognizerStateEnded,

    /**
     * A continous event already recognized has been cancelled.
     *
     * From this state, the event recognizer will automatically move to
     * <VELEventRecognizerStatePossible> after invoking its action blocks.
     */
    VELEventRecognizerStateCancelled,

    /**
     * The event recognizer failed to recognize a discrete event.
     *
     * From this state, the event recognizer will automatically move to
     * <VELEventRecognizerStatePossible> after invoking its action blocks.
     */
    VELEventRecognizerStateFailed,

    /**
     * The event recognizer has recognized a discrete event.
     *
     * From this state, the event recognizer will automatically move to
     * <VELEventRecognizerStatePossible> after invoking its action blocks.
     */
    VELEventRecognizerStateRecognized = VELEventRecognizerStateEnded
} VELEventRecognizerState;

/**
 * Returns a string representation of `state`.
 *
 * This is for debugging, and is not localized.
 */
NSString *NSStringFromVELEventRecognizerState(VELEventRecognizerState state);

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
 *
 * When an event is about to be dispatched to any view that has attached
 * recognizers, or any ancestors with attached recognizers, the event will be
 * delivered to any recognizers before being delivered to any of the views. The
 * order in which the event is delivered to the recognizers depends on the value
 * of <handlesEventsAfterDescendants>. If <delaysEventDelivery> is `YES` for any
 * recognizer in the chain, the original view (the one that was going to receive
 * the event) will not receive the event until that recognizer has transitioned
 * states.
 *
 * If a given recognizer depends on another,
 * <shouldPreventEventRecognizer:fromReceivingEvent:>,
 * <shouldBePreventedByEventRecognizer:fromReceivingEvent:>, and
 * <recognizersRequiredToFail> can be used to alter the order of event delivery
 * or entirely prevent certain recognizers from receiving certain events.
 */
@interface VELEventRecognizer : NSObject

/**
 * @name Attaching Recognizers to a View
 */

/**
 * Returns an array containing all event recognizers with a <view> property set
 * to the given view. If no such recognizers exist, returns `nil`.
 *
 * @param view A view to return the event recognizers of.
 */
+ (NSArray *)eventRecognizersForView:(id<VELBridgedView>)view;

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
 * Invoked to test whether the receiver should handle the given event.
 *
 * If this block returns `NO`, `event` will not be delivered to the receiver.
 *
 * The default value for this property is `nil`, which means that all events
 * should be received (assuming no other recognizers prevent their delivery).
 */
@property (nonatomic, copy) BOOL (^shouldReceiveEventBlock)(NSEvent *event);

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
 * Whether the receiver should only receive each event after any applicable
 * descendant recognizers have received the event.
 *
 * If set to `NO`, ancestor recognizers (those attached to views higher up in
 * the hierarchy) will receive the event first, followed by their immediate
 * descendants, and so on. If set to `YES` on both a recognizer and its child,
 * the former will receive events after the latter.
 *
 * This flag does not affect _which_ recognizers receive the event -- only the
 * order in which they do.
 *
 * The default value for this property is `NO`.
 */
@property (nonatomic, assign) BOOL handlesEventsAfterDescendants;

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
 * Invoked to test whether the receiver should prevent `recognizer` from
 * receiving `event`.
 *
 * If this block returns `YES`, `event` will not be delivered to `recognizer`.
 *
 * This block is invoked from the default implementation of
 * <shouldPreventEventRecognizer:fromReceivingEvent:>.
 *
 * The default value for this property is `nil`.
 */
@property (nonatomic, copy) BOOL (^shouldPreventEventRecognizerBlock)(VELEventRecognizer *recognizer, NSEvent *event);

/**
 * Invoked to test whether `recognizer` should prevent the receiver from
 * receiving `event`.
 *
 * If this block returns `YES`, `event` will not be delivered to the receiver.
 *
 * This block is invoked from the default implementation of
 * <shouldBePreventedByEventRecognizer:fromReceivingEvent:>.
 *
 * The default value for this property is `nil`.
 */
@property (nonatomic, copy) BOOL (^shouldBePreventedByEventRecognizerBlock)(VELEventRecognizer *recognizer, NSEvent *event);

/**
 * Whether the receiver should prevent the given event recognizer from receiving
 * the given event.
 *
 * If this method returns `YES`, `event` will not be delivered to `recognizer`.
 *
 * This method will be invoked every time an event is dispatched to a view that
 * has attached recognizers, or any ancestors with attached recognizers. This
 * method will be invoked on _descendant_ recognizers first, thus giving them
 * a chance to prevent event delivery to recognizers further up the chain.
 *
 * The default implementation of this method invokes any
 * <shouldPreventEventRecognizerBlock> that has been set, and returns the
 * result. If no <shouldBePreventedByEventRecognizerBlock> has been set, `NO` is
 * returned.
 *
 * @param recognizer Another event recognizer.
 * @param event An event being considered for delivery to `recognizer`.
 */
- (BOOL)shouldPreventEventRecognizer:(VELEventRecognizer *)recognizer fromReceivingEvent:(NSEvent *)event;

/**
 * Whether the given event recognizer should prevent the receiver from receiving
 * the given event.
 *
 * If this method returns `YES`, `event` will not be delivered to the receiver.
 *
 * This method will be invoked every time an event is dispatched to a view that
 * has attached recognizers, or any ancestors with attached recognizers. This
 * method will be invoked on _ancestor_ recognizers first, thus giving
 * descendants a chance to prevent event delivery to recognizers further up the
 * chain.
 *
 * The default implementation of this method invokes and
 * <shouldBePreventedByEventRecognizerBlock> that has been set, and returns the
 * result. If no <shouldBePreventedByEventRecognizerBlock> has been set, `NO` is
 * returned.
 *
 * @param recognizer Another event recognizer.
 * @param event An event being considered for delivery to the receiver.
 */
- (BOOL)shouldBePreventedByEventRecognizer:(VELEventRecognizer *)recognizer fromReceivingEvent:(NSEvent *)event;

/**
 * @name Controlling Event Delivery
 */

/**
 * Whether the receiver should delay `NSEvent` delivery to its <view> until it
 * has failed to recognize its event.
 *
 * In other words, if this is set to `YES`, the receiver will capture `NSEvent`
 * objects meant for its <view> (or any descendants) while simultaneously trying
 * to recognize its event. If the event is successfully recognized, the
 * `NSEvent` objects are never delivered to the view. If the event fails to be
 * recognized, then the `NSEvent` objects are re-dispatched in the order they
 * arrived, using `-[NSApplication sendEvent:]`.
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
- (id)addActionUsingBlock:(void (^)(id recognizer))block;

/**
 * De-registers a block previously added with <addActionUsingBlock:>.
 *
 * @param action An object returned from <addActionUsingBlock:> corresponding to
 * the block that you wish to de-register.
 */
- (void)removeAction:(id)action;

/**
 * De-registers all blocks that have been added with <addActionUsingBlock:>.
 */
- (void)removeAllActions;

@end
