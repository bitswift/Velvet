//
//  VELEventManager.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELEventManager.h"
#import "NSWindow+EventHandlingAdditions.h"
#import "VELView.h"
#import "EXTScope.h"

@interface VELEventManager ()
/*
 * Any Velvet-hosted responder currently handling a continuous gesture event.
 */
@property (nonatomic, strong) id currentGestureResponder;

/*
 * Whether an event is currently in the process of being handled in
 * <handleVelvetEvent:>.
 *
 * This is used to avoid infinite recursion, as apparently some `NSResponder`
 * messages eventually jump back up to event monitors.
 */
@property (nonatomic, assign, getter = isHandlingEvent) BOOL handlingEvent;

/**
 * Returns YES if an event was generated in Velvet for the last mouse down event
 * that routed through the event manager.
 *
 * This is used to decide whether to send mouse drag and up events in Velvet.
 */
@property (nonatomic, assign) BOOL velvetHandledLastMouseDown;

/*
 * Turns an event into an `NSResponder` message, and attempts to send it to the
 * given responder. If neither `responder` nor the rest of its responder chain
 * implement the corresponding action, `NO` is returned.
 *
 * @param event The event to dispatch.
 * @param responder The `NSResponder` which should receive the message
 * corresponding to `event`.
 */
- (BOOL)dispatchEvent:(NSEvent *)event toResponder:(NSResponder *)responder;

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
@synthesize handlingEvent = m_handlingEvent;
@synthesize velvetHandledLastMouseDown = m_velvetHandledLastMouseDown;

#pragma mark Lifecycle

+ (void)load {
    [NSEvent addLocalMonitorForEventsMatchingMask:NSAnyEventMask handler:^ id (NSEvent *event){
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

- (BOOL)dispatchEvent:(NSEvent *)event toResponder:(NSResponder *)responder; {
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

        default:
            NSLog(@"*** Unrecognized event: %@", event);
    }

    if (action)
        return [responder tryToPerform:action with:event];
    else
        return NO;
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

    id respondingView = nil;

    switch ([event type]) {
        case NSLeftMouseDown:
        case NSRightMouseDown:
        case NSOtherMouseDown:
            respondingView = [event.window bridgedHitTest:[event locationInWindow]];
            
            if (respondingView) {
                // make the view that received the click the first responder for
                // that window
                [event.window makeFirstResponder:respondingView];
            }

            self.velvetHandledLastMouseDown = (respondingView != nil);
            break;

        case NSScrollWheel:
        case NSEventTypeMagnify:
        case NSEventTypeSwipe:
        case NSEventTypeRotate:
            respondingView = [event.window bridgedHitTest:[event locationInWindow]];
            break;

        case NSEventTypeBeginGesture:
            self.currentGestureResponder = respondingView = [event.window bridgedHitTest:[event locationInWindow]];
            break;

        case NSEventTypeEndGesture:
            respondingView = self.currentGestureResponder;
            self.currentGestureResponder = nil;

            break;

        case NSLeftMouseUp:
        case NSRightMouseUp:
        case NSLeftMouseDragged:
        case NSRightMouseDragged:
        case NSOtherMouseUp:
        case NSOtherMouseDragged:
            if (!self.velvetHandledLastMouseDown)
                return NO;

            // Otherwise, fall through

        case NSMouseMoved:
        case NSMouseEntered:
        case NSMouseExited: {
            id responder = [event.window firstResponder];
            if (![responder isKindOfClass:[NSView class]]) {
                [self dispatchEvent:event toResponder:responder];
            }

            // we always want to pass on these kinds of mouse events to the
            // window, since it does some magic
            return NO;
        }

        default:
            // any other kind of event is not handled by us
            ;
    }

    if (respondingView) {
        return [self dispatchEvent:event toResponder:respondingView];
    } else {
        return NO;
    }
}

@end
