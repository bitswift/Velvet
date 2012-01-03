//
//  VELEventManager.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Emerald Lark. All rights reserved.
//

#import <Velvet/VELEventManager.h>
#import <Velvet/NSWindow+EventHandlingAdditions.h>
#import <Velvet/VELView.h>
#import <Proton/Proton.h>

@interface VELEventManager ()
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
    switch ([event type]) {
        case NSLeftMouseDown:
            [responder mouseDown:event];
            break;

        case NSLeftMouseUp:
            [responder mouseUp:event];
            break;

        case NSRightMouseDown:
            [responder rightMouseDown:event];
            break;

        case NSRightMouseUp:
            [responder rightMouseUp:event];
            break;

        case NSMouseMoved:
            [responder mouseMoved:event];
            break;

        case NSLeftMouseDragged:
            [responder mouseDragged:event];
            break;

        case NSRightMouseDragged:
            [responder rightMouseDragged:event];
            break;

        case NSMouseEntered:
            [responder mouseEntered:event];
            break;

        case NSMouseExited:
            [responder mouseExited:event];
            break;

        case NSOtherMouseDown:
            [responder otherMouseDown:event];
            break;

        case NSOtherMouseUp:
            [responder otherMouseUp:event];
            break;

        case NSOtherMouseDragged:
            [responder otherMouseDragged:event];
            break;
        
        case NSScrollWheel:
            [responder scrollWheel:event];
            break;

        default:
            DDLogError(@"Unrecognized event: %@", event);
    }
}

- (BOOL)handleVelvetEvent:(NSEvent *)theEvent; {
    VELView *respondingView = nil;

    switch ([theEvent type]) {
        case NSLeftMouseDown:
        case NSRightMouseDown:
        case NSOtherMouseDown:
            respondingView = [theEvent.window velvetViewForMouseDownEvent:theEvent];
            
            if (respondingView) {
                // make the view that received the click the first responder for
                // that window
                [theEvent.window makeFirstResponder:respondingView];
            }

            break;

        case NSScrollWheel:
            respondingView = [theEvent.window velvetViewForScrollEvent:theEvent];
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
            if ([responder isKindOfClass:[VELView class]]) {
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
