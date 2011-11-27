//
//  VELWindow.m
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELWindow.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSVelvetHostView.h>
#import <Velvet/VELView.h>
#import <Velvet/VELNSView.h>
#import <Velvet/NSView+VELGeometryAdditions.h>

@class NSVelvetHostView;

@interface VELWindow ()
/*
 * Turns an event into an `NSResponder` message, and sends it to
 * a responder.
 *
 * @param event The event to dispatch.
 * @param responder The `NSResponder` which should receive the message
 * corresponding to `event`.
 */
- (void)dispatchEvent:(NSEvent *)event toResponder:(NSResponder *)responder;

/*
 * Sends a mouse-down event to the <VELView> in the clicked region. The
 * <VELView> is made the first responder.
 *
 * If the event didn't occur inside a <VELView>, the event is handed off to
 * AppKit and tested against any `NSView` hierarchies.
 *
 * @param event The mouse-down event which occurred.
 */
- (void)sendMouseDownEvent:(NSEvent *)event;
@end

@implementation VELWindow

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

        default:
            NSLog(@"Unrecognized event %@", event);
    }
}

- (void)sendEvent:(NSEvent *)theEvent {
    switch ([theEvent type]) {
        case NSLeftMouseDown:
        case NSRightMouseDown:
        case NSOtherMouseDown:
            [self sendMouseDownEvent:theEvent];
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
            id responder = [self firstResponder];
            if ([responder isKindOfClass:[VELView class]]) {
                [self dispatchEvent:theEvent toResponder:responder];
                return;
            }
        }

        // Fall through to here when the first responder isn't a VELView
        default:
            [super sendEvent:theEvent];
    }
}

- (void)sendMouseDownEvent:(NSEvent *)event {
    NSAssert([self.contentView isKindOfClass:[NSVelvetView class]], @"Window %@ does not have an NSVelvetView as its content view", self);

    id velvetView = [(id)self.contentView rootView];
    CGPoint windowPoint = NSPointToCGPoint([event locationInWindow]);

    while (YES) {
        if ([velvetView isKindOfClass:[VELNSView class]]) {
            NSView *nsView = [velvetView NSView];

            NSPoint viewPoint = NSPointFromCGPoint([[nsView superview] convertFromWindowPoint:windowPoint]);
            id testView = [nsView hitTest:viewPoint];

            if (![testView isKindOfClass:[NSVelvetView class]]) {
                [super sendEvent:event];
                break;
            }

            NSVelvetView *hostView = testView;
            velvetView = hostView.rootView;
        } else {
            CGPoint viewPoint = [velvetView convertFromWindowPoint:windowPoint];
            id testView = [velvetView hitTest:viewPoint];

            if (![testView isKindOfClass:[VELNSView class]]) {
                [self dispatchEvent:event toResponder:testView];
                [self makeFirstResponder:testView];
                break;
            }

            velvetView = testView;
        }
    }
}

@end
