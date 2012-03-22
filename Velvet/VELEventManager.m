//
//  VELEventManager.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELEventManager.h"
#import "CGGeometry+ConvenienceAdditions.h"
#import "EXTScope.h"
#import "NSEvent+ButtonStateAdditions.h"
#import "NSWindow+EventHandlingAdditions.h"
#import "VELEventRecognizerPrivate.h"
#import "VELEventRecognizerProtected.h"
#import "VELHostView.h"
#import "VELKeyPress.h"
#import "VELKeyPressEventRecognizer.h"
#import "VELView.h"

/**
 * Walks up the hierarchy of the given view, collecting all enabled event
 * recognizers into the given array.
 *
 * The given array will contain ancestor recognizers first, followed by their
 * immediate children, and so on. Any disabled recognizers will be omitted from
 * the array.
 *
 * @param recognizers A mutable array to add recognizers to. This should be
 * provided as an empty array.
 * @param view A view from which retrieve all attached recognizers. This may be
 * `nil`.
 */
static void getEventRecognizersFromViewHierarchy (NSMutableArray *recognizers, id<VELBridgedView> view) {
    NSCParameterAssert(recognizers != nil);

    if (!view)
        return;

    /*
     * We shouldn't consider <[VELEventRecognizer
     * handlesEventsAfterDescendants]> in here, because we always want the
     * prevention blocks (invoked in <dispatchEvent:toEventRecognizersForView:>)
     * to be called descendants-first. Adjusting the order of the array here
     * would violate that guarantee.
     */
    getEventRecognizersFromViewHierarchy(recognizers, view.immediateParentView);

    NSArray *attachedRecognizers = [VELEventRecognizer eventRecognizersForView:view];
    for (VELEventRecognizer *recognizer in attachedRecognizers) {
        if (recognizer.enabled)
            [recognizers addObject:recognizer];
    }
}

/**
 * Dispatches the given event to the recognizers at and after the given index.
 * Returns whether the event should still be passed to the view.
 *
 * This function takes into account the value of <[VELEventRecognizer
 * handlesEventsAfterDescendants]>, to make sure that ancestors with that flag
 * enabled are only invoked after the rest of the recognizers (the descendants)
 * have received the event.
 *
 * @param event The event to dispatch.
 * @param recognizers An array of event recognizers, with ancestors at the
 * beginning of the array.
 * @param index The index into `recognizers` at which to begin event dispatch.
 * If this index is out-of-bounds, the function returns `YES` immediately.
 */
static BOOL dispatchEventToRecognizersStartingAtIndex (NSEvent *event, NSArray *recognizers, NSUInteger index) {
    NSCParameterAssert(event);
    NSCParameterAssert(recognizers);

    if (index >= recognizers.count)
        return YES;

    VELEventRecognizer *recognizer = [recognizers objectAtIndex:index];
    BOOL dispatchToView = YES;

    BOOL handlesAfterDescendants = recognizer.handlesEventsAfterDescendants;
    if (handlesAfterDescendants) {
        // dispatch to descendants first
        dispatchToView &= dispatchEventToRecognizersStartingAtIndex(event, recognizers, index + 1);
    }

    if (!recognizer.shouldReceiveEventBlock || recognizer.shouldReceiveEventBlock(event)) {
        if ([recognizer.eventsToIgnore containsObject:event]) {
            [recognizer.eventsToIgnore removeObject:event];
        } else {
            BOOL handled = [recognizer handleEvent:event];

            // don't forward the event to the view if this recognizer wants it
            // delayed
            if (handled && recognizer.delaysEventDelivery)
                dispatchToView = NO;
        }
    }

    if (!handlesAfterDescendants) {
        // dispatch to descendants after this recognizer has had a chance to
        // process the event
        dispatchToView &= dispatchEventToRecognizersStartingAtIndex(event, recognizers, index + 1);
    }

    return dispatchToView;
}

@interface VELEventManager ()
/**
 * Any Velvet-hosted responder currently handling a continuous gesture event.
 */
@property (nonatomic, strong) id<VELBridgedView> currentGestureResponder;

/**
 * The Velvet-hosted responder that handled the last mouse down or mouse drag
 * event.
 */
@property (nonatomic, strong) id<VELBridgedView> currentMouseDownResponder;

/**
 * The Velvet-hosted responder that received the last handled mouse tracking
 * event.
 */
@property (nonatomic, weak) id lastMouseTrackingResponder;

/**
 * Whether an event is currently in the process of being handled in
 * <handleVelvetEvent:>.
 *
 * This is used to avoid infinite recursion, as apparently some `NSResponder`
 * messages eventually jump back up to event monitors.
 */
@property (nonatomic, assign, getter = isHandlingEvent) BOOL handlingEvent;

/**
 * Turns an event into an `NSResponder` message, and attempts to send it to the
 * given responder. If neither `responder` nor the rest of its responder chain
 * implement the corresponding action, `NO` is returned.
 *
 * @param event The event to dispatch.
 * @param view The <VELBridgedView> which should receive the message
 * corresponding to `event`. This view must be an `NSResponder`.
 */
- (BOOL)dispatchEvent:(NSEvent *)event toBridgedView:(id<VELBridgedView>)view;

/**
 * Dispatches the given event to all of the event recognizers that are directly
 * or indirectly attached to the given view. Returns whether the event should
 * still be passed to the view.
 *
 * In other words, this returns `NO` if one or more of the event recognizers has
 * <[VELEventRecognizer delaysEventDelivery]> set to `YES`.
 *
 * This method will dispatch events to the farthest ancestors first, then walk
 * down the tree, eventually ending at `view`. If the given view has
 * a <[VELBridgedView hostView]> that is not an ancestor, the host view's event
 * recognizers will receive `event` before those of `view`.
 *
 * @param event The event to dispatch.
 * @param view A view that may have attached event recognizers, or may have
 * superviews or a <[VELBridgedView hostView]> with attached event recognizers.
 */
- (BOOL)dispatchEvent:(NSEvent *)event toEventRecognizersForView:(id<VELBridgedView>)view;

/**
 * Attempts to dispatch the given mouse tracking event (`NSMouseEntered`,
 * `NSMouseMoved` or `NSMouseExited`) to Velvet. Regardless of whether the event
 * was handled by Velvet, it should _not_ be discarded.
 *
 * This may translate into a different message than suggested by the exact event
 * type, or several events, in Velvet. For instance, an `NSMouseMoved` event may
 * trigger `mouseExited:` and `mouseEntered:` events on Velvet hosted views.
 *
 * @param event The event that occurred.
 */
- (void)handleMouseTrackingEvent:(NSEvent *)event;

/**
 * If the given event doesn't have an associated window, give it one, and update
 * its location accordingly.
 *
 * This currently just uses the application's `keyWindow` as the receiver, no
 * matter where the event is.
 *
 * @param event The event that may have a `nil` window.
 */
- (NSEvent *)mouseEventByAddingWindow:(NSEvent *)event;

/**
 * Attempts to dispatch the given event to Velvet via the appropriate window.
 * Returns whether the event was handled by Velvet (and thus should be
 * disregarded by AppKit).
 *
 * @param event The event that occurred.
 */
- (BOOL)handleVelvetEvent:(NSEvent *)event;
@end

@implementation VELEventManager

#pragma mark Properties

@synthesize currentGestureResponder = m_currentGestureResponder;
@synthesize currentMouseDownResponder = m_currentMouseDownResponder;
@synthesize handlingEvent = m_handlingEvent;
@synthesize lastMouseTrackingResponder = m_lastMouseTrackingResponder;

#pragma mark Lifecycle

+ (void)load {
    // set up a global event recognizer for VELHostView debug mode
    #ifdef DEBUG
    __block BOOL hostViewDebugModeEnabled = NO;

    NSMutableArray *keyPresses = [NSMutableArray array];
    for (unsigned i = 0; i < 3; ++i) {
        VELKeyPress *keyPress = [[VELKeyPress alloc] initWithCharactersIgnoringModifiers:nil modifierFlags:NSControlKeyMask];
        [keyPresses addObject:keyPress];
    }

    VELKeyPressEventRecognizer *recognizer = [[VELKeyPressEventRecognizer alloc] init];
    recognizer.keyPressesToRecognize = keyPresses;

    [recognizer addActionUsingBlock:^(VELKeyPressEventRecognizer *recognizer){
        if (!recognizer.active)
            return;

        hostViewDebugModeEnabled = !hostViewDebugModeEnabled;
        if (hostViewDebugModeEnabled) {
            NSLog(@"*** Enabling host view debug mode");
        } else {
            NSLog(@"*** Disabling host view debug mode");
        }

        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:hostViewDebugModeEnabled] forKey:VELHostViewDebugModeIsEnabledKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:VELHostViewDebugModeChangedNotification object:self userInfo:userInfo];
    }];
    #endif

    [NSEvent addLocalMonitorForEventsMatchingMask:NSAnyEventMask handler:^ id (NSEvent *event){
        #ifdef DEBUG
        [recognizer handleEvent:event];
        #endif

        if ([[self defaultManager] handleVelvetEvent:event])
            return nil;
        else
            return event;
    }];
}

+ (id)defaultManager {
    static id singleton = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        singleton = [[self alloc] init];
    });

    return singleton;
}

#pragma mark Event handling

- (BOOL)dispatchEvent:(NSEvent *)event toBridgedView:(id<VELBridgedView>)view; {
    NSAssert([view isKindOfClass:[NSResponder class]], @"View %@ is not an NSResponder", view);

    SEL action = NULL;

    switch ([event type]) {
        case NSLeftMouseDown:
            action = @selector(mouseDown:);
            break;

        case NSLeftMouseUp:
            action = @selector(mouseUp:);
            break;

        case NSRightMouseDown:
            action = @selector(rightMouseDown:);
            break;

        case NSRightMouseUp:
            action = @selector(rightMouseUp:);
            break;

        case NSMouseMoved:
            action = @selector(mouseMoved:);
            break;

        case NSLeftMouseDragged:
            action = @selector(mouseDragged:);
            break;

        case NSRightMouseDragged:
            action = @selector(rightMouseDragged:);
            break;

        case NSMouseEntered:
            action = @selector(mouseEntered:);
            break;

        case NSMouseExited:
            action = @selector(mouseExited:);
            break;

        case NSOtherMouseDown:
            action = @selector(otherMouseDown:);
            break;

        case NSOtherMouseUp:
            action = @selector(otherMouseUp:);
            break;

        case NSOtherMouseDragged:
            action = @selector(otherMouseDragged:);
            break;
        
        case NSScrollWheel:
            action = @selector(scrollWheel:);
            break;

        case NSEventTypeMagnify:
            action = @selector(magnifyWithEvent:);
            break;

        case NSEventTypeSwipe:
            action = @selector(swipeWithEvent:);
            break;

        case NSEventTypeRotate:
            action = @selector(rotateWithEvent:);
            break;

        case NSEventTypeBeginGesture:
            action = @selector(beginGestureWithEvent:);
            break;

        case NSEventTypeEndGesture:
            action = @selector(endGestureWithEvent:);
            break;

        case NSKeyDown:
            action = @selector(keyDown:);
            break;

        case NSKeyUp:
            action = @selector(keyUp:);
            break;

        case NSFlagsChanged:
            action = @selector(flagsChanged:);
            break;

        default:
            NSLog(@"*** Unrecognized event: %@", event);
    }

    if (action)
        return [(id)view tryToPerform:action with:event];
    else
        return NO;
}

- (BOOL)dispatchEvent:(NSEvent *)event toEventRecognizersForView:(id<VELBridgedView>)view; {
    NSParameterAssert(event != nil);
    NSParameterAssert(view != nil);

    NSMutableArray *recognizers = [NSMutableArray array];
    getEventRecognizersFromViewHierarchy(recognizers, view);

    if (!recognizers.count)
        return YES;

    // find recognizers that prevent each other (descendants first, so that they
    // can prevent ancestors)
    NSUInteger i = recognizers.count - 1;
    do {
        VELEventRecognizer *first = [recognizers objectAtIndex:i];

        NSUInteger j = recognizers.count - 1;
        do {
            if (i == j) {
                // this is the same recognizer, skip it
                continue;
            }

            VELEventRecognizer *second = [recognizers objectAtIndex:j];
            if ([first shouldPreventEventRecognizer:second fromReceivingEvent:event] || [second shouldBePreventedByEventRecognizer:first fromReceivingEvent:event]) {
                [recognizers removeObjectAtIndex:j];

                if (i > j)
                    --i;
            }
        } while (j-- > 0);
    } while (i-- > 0);

    return dispatchEventToRecognizersStartingAtIndex(event, recognizers, 0);
}

- (BOOL)handleVelvetEvent:(NSEvent *)event; {
    if (self.handlingEvent) {
        // don't recurse -- see the description for this property
        return NO;
    }

    self.handlingEvent = YES;
    @onExit {
        self.handlingEvent = NO;
    };

    __block id respondingView = nil;

    // whether the event was received by an event recognizer and delayed from
    // delivery
    __block BOOL eventAbsorbedByRecognizer = NO;

    /**
     * Returns whether we should handle the event dispatch for `respondingView`.
     * If this returns `NO`, the event should be returned to AppKit for
     * processing.
     */
    BOOL (^velvetShouldHandleRespondingView)(void) = ^ BOOL {
        return respondingView && ![respondingView isKindOfClass:[NSView class]];
    };

    /**
     * Attempts to dispatch the event to `respondingView`. Returns whether the
     * event should be considered handled.
     */
    BOOL (^dispatchToView)(void) = ^{
        if (![respondingView conformsToProtocol:@protocol(VELBridgedView)])
            return NO;

        if (![self dispatchEvent:event toEventRecognizersForView:respondingView]) {
            eventAbsorbedByRecognizer = YES;
            return YES;
        }

        if (!velvetShouldHandleRespondingView())
            return NO;

        return [self dispatchEvent:event toBridgedView:respondingView];
    };

    switch ([event type]) {
        case NSLeftMouseDown:
        case NSRightMouseDown:
        case NSOtherMouseDown:
            respondingView = [event.window bridgedHitTest:[event locationInWindow] withEvent:event];
            if (!dispatchToView()) {
                self.currentMouseDownResponder = nil;
                return NO;
            }

            if (!eventAbsorbedByRecognizer) {
                NSAssert([respondingView isKindOfClass:[NSResponder class]], @"View %@ is not an NSResponder", respondingView);

                // make the view that received the click the first responder for
                // that window
                [event.window makeFirstResponder:(id)respondingView];
            }

            self.currentMouseDownResponder = respondingView;
            return YES;

        case NSScrollWheel:
        case NSEventTypeMagnify:
        case NSEventTypeSwipe:
        case NSEventTypeRotate:
            respondingView = [event.window bridgedHitTest:[event locationInWindow] withEvent:event];
            break;

        case NSEventTypeBeginGesture:
            respondingView = [event.window bridgedHitTest:[event locationInWindow] withEvent:event];
            if (velvetShouldHandleRespondingView()) {
                self.currentGestureResponder = respondingView;
            }

            break;

        case NSEventTypeEndGesture:
            respondingView = self.currentGestureResponder;
            self.currentGestureResponder = nil;

            break;

        case NSLeftMouseUp:
        case NSRightMouseUp:
        case NSOtherMouseUp:
            respondingView = (id)self.currentMouseDownResponder ?: [event.window firstResponder];

            self.currentMouseDownResponder = nil;
            break;

        case NSLeftMouseDragged:
        case NSRightMouseDragged:
        case NSOtherMouseDragged:
            respondingView = (id)self.currentMouseDownResponder ?: [event.window firstResponder];
            break;

        case NSMouseMoved:
        case NSMouseEntered:
        case NSMouseExited:
            [self handleMouseTrackingEvent:event];
            return NO;

        default: {
            // assume this kind of event would go to the first responder, so
            // dispatch to any event recognizers for it
            id view = [event.window firstResponder];
            if (view == event.window) {
                view = event.window.contentView;
            }

            if (view && ![view conformsToProtocol:@protocol(VELBridgedView)])
                return NO;

            // this might be some kind of event that isn't technically a mouse
            // event, but still has that kind of information
            if (event.hasMouseButtonState) {
                // convert to actual mouse events, and dispatch only to our
                // event recognizers
                NSArray *mouseEvents = event.correspondingMouseEvents;

                BOOL consumed = NO;
                for (NSEvent *mouseEvent in mouseEvents) {
                    NSEvent *windowedMouseEvent = [self mouseEventByAddingWindow:mouseEvent];

                    // see if the next mouse event would duplicate this one
                    NSEvent *nextMouseEvent = [NSApp
                        nextEventMatchingMask:NSEventMaskFromType(windowedMouseEvent.type)
                        untilDate:nil
                        inMode:NSDefaultRunLoopMode
                        dequeue:NO
                    ];

                    BOOL duplicateOfNextMouseEvent = 
                        [windowedMouseEvent.window isEqual:nextMouseEvent.window] &&
                        CGPointEqualToPointWithAccuracy(windowedMouseEvent.locationInWindow, nextMouseEvent.locationInWindow, 0.1) &&
                        fabs(windowedMouseEvent.timestamp - nextMouseEvent.timestamp) < 0.1
                    ;

                    if (duplicateOfNextMouseEvent) {
                        // don't dispatch the converted NSSystemDefined event,
                        // since the actual one coming through would result in
                        // duplicate event dispatch
                        continue;
                    }

                    if (!view) {
                        view = [windowedMouseEvent.window bridgedHitTest:windowedMouseEvent.locationInWindow withEvent:windowedMouseEvent];
                        if (!view)
                            continue;
                    }

                    consumed |= [self dispatchEvent:windowedMouseEvent toEventRecognizersForView:view];
                }

                if (consumed)
                    return YES;
            } else if (view) {
                // otherwise, just pass it down normally
                if (![self dispatchEvent:event toEventRecognizersForView:view])
                    return YES;
            }

            return NO;
        }
    }

    return dispatchToView();
}

- (NSPoint)convertScreenPoint:(NSPoint)point toWindow:(NSWindow *)window {
    if (!window)
        return point;

    NSRect r = NSMakeRect(point.x, point.y, 1, 1);
    r = [window convertRectFromScreen:r];
    return r.origin;
}

- (NSEvent *)mouseEventByAddingWindow:(NSEvent *)event {
    if (!event || event.window)
        return event;

    NSWindow *matchingWindow = nil;
    CGPoint windowLocation;
    
    for (NSWindow *window in [NSApp windows]) {
        if (![window isVisible])
            continue;

        CGPoint screenPoint = event.locationInWindow;
        if (!CGRectContainsPoint(window.frame, screenPoint))
            continue;

        matchingWindow = window;
        windowLocation = [self convertScreenPoint:event.locationInWindow toWindow:window];
    }

    if (!matchingWindow)
        return nil;

    NSEvent *windowEvent = [NSEvent mouseEventWithType:event.type
        location:windowLocation
        modifierFlags:event.modifierFlags
        timestamp:event.timestamp
        windowNumber:matchingWindow.windowNumber
        context:matchingWindow.graphicsContext
        eventNumber:event.eventNumber
        clickCount:event.clickCount
        pressure:event.pressure
    ];

    return windowEvent;
}

- (void)handleMouseTrackingEvent:(NSEvent *)event {
    // Try to determine the window to get the event.
    event = [self mouseEventByAddingWindow:event];
    if (!event)
        return;

    id hitView = [event.window bridgedHitTest:[event locationInWindow] withEvent:event];
    if (hitView == self.lastMouseTrackingResponder) {
        [hitView tryToPerform:@selector(mouseMoved:) with:event];
        return;
    }

    [self.lastMouseTrackingResponder tryToPerform:@selector(mouseExited:) with:event];

    if ([hitView isKindOfClass:[NSView class]]) {
        self.lastMouseTrackingResponder = nil;
        return;
    }

    [event.window setAcceptsMouseMovedEvents:YES];

    self.lastMouseTrackingResponder = hitView;
    [hitView tryToPerform:@selector(mouseEntered:) with:event];
}

@end
