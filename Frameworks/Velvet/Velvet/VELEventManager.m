//
//  VELEventManager.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELEventManager.h>
#import <Velvet/NSWindow+EventHandlingAdditions.h>
#import <Velvet/VELView.h>
#import <Proton/Proton.h>

@interface VELEventManager ()
/*
 * Any Velvet-hosted responder currently handling a continuous gesture event.
 */
@property (nonatomic, strong) id currentGestureResponder;

/*
 * Turns an event into an `NSResponder` message, and sends it to
 * a responder.
 *
 * @param event The event to dispatch.
 * @param responder The `NSResponder` which should receive the message
 * corresponding to `event`.
 */
- (void)dispatchEvent:(NSEvent *)event toResponder:(NSResponder *)responder;

/**
 * Attempts to dispatch the given event to Velvet via the appropriate window.
 * Returns whether the event was handled by Velvet (and thus should be
 * disregarded by AppKit).
 *
 * @param theEvent The event that occurred.
 */
- (BOOL)handleVelvetEvent:(NSEvent *)theEvent;
@end

@implementation VELEventManager

#pragma mark Properties

@synthesize currentGestureResponder = m_currentGestureResponder;

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

- (void)dispatchEvent:(NSEvent *)event toResponder:(NSResponder *)responder; {
    SEL action;

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
            DDLogError(@"Unrecognized event: %@", event);
            return;
    }

    [responder doCommandBySelector:action];
}

- (BOOL)handleVelvetEvent:(NSEvent *)theEvent; {
    id respondingView = nil;

    switch ([theEvent type]) {
        case NSLeftMouseDown:
        case NSRightMouseDown:
        case NSOtherMouseDown:
            respondingView = [theEvent.window bridgedViewForMouseDownEvent:theEvent];
            
            if (respondingView) {
                BOOL (^isNextResponderOfExistingResponder)(void) = ^ BOOL {
                    NSResponder *responder = [theEvent.window firstResponder];
                    
                    while (responder && responder != respondingView)
                        responder = responder.nextResponder;

                    return responder != nil;
                };

                if (!isNextResponderOfExistingResponder()) {
                    // make the view that received the click the first responder for
                    // that window
                    [theEvent.window makeFirstResponder:respondingView];
                }
            }

            break;

        case NSScrollWheel:
        case NSEventTypeMagnify:
        case NSEventTypeSwipe:
        case NSEventTypeRotate:
            respondingView = [theEvent.window bridgedViewForScrollEvent:theEvent];
            break;

        case NSEventTypeBeginGesture:
            self.currentGestureResponder = respondingView = [theEvent.window bridgedViewForScrollEvent:theEvent];
            break;

        case NSEventTypeEndGesture:
            respondingView = self.currentGestureResponder;
            self.currentGestureResponder = nil;

            break;

        case NSLeftMouseUp:
        case NSRightMouseUp:
        case NSMouseMoved:
        case NSLeftMouseDragged:
        case NSRightMouseDragged:
        case NSMouseEntered:
        case NSMouseExited:
        case NSOtherMouseUp:
        case NSOtherMouseDragged: {
            id responder = [theEvent.window firstResponder];
            if (![responder isKindOfClass:[NSView class]]) {
                [self dispatchEvent:theEvent toResponder:responder];
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
        [self dispatchEvent:theEvent toResponder:respondingView];
        return YES;
    } else {
        return NO;
    }
}

@end
