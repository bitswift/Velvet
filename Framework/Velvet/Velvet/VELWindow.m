//
//  VELWindow.m
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELWindow.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSVelvetViewPrivate.h>
#import <Velvet/NSVelvetHostView.h>
#import <Velvet/VELView.h>
#import <Velvet/VELNSView.h>
#import <Velvet/NSView+ScrollViewAdditions.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>

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
 * Returns the <VELView> or `NSView` which is occupying the given point, or
 * `nil` if there is no such view.
 *
 * @param windowPoint A point, specified in the coordinate system of the window,
 * at which to look for a view.
 */
- (id)bridgedHitTest:(CGPoint)windowPoint;

/*
 * Hit tests for a <VELView> in the region identified by the given event,
 * sending the event to any <VELView> that is found.
 *
 * The <VELView> is made the first responder.
 *
 * If the event didn't occur inside a <VELView>, the event is handed off to
 * AppKit and tested against any `NSView` hierarchies.
 *
 * @param event The mouse-related event which occurred.
 */
- (void)sendHitTestedEvent:(NSEvent *)event;

/*
 * Sends a scroll wheel event to the most descendant scroll view (either Velvet
 * or AppKit) in the region identified by the given event.
 *
 * @param event The scroll wheel event which occurred.
 */
- (void)sendScrollEvent:(NSEvent *)event;
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
        
        case NSScrollWheel:
            [responder scrollWheel:event];
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
            [self sendHitTestedEvent:theEvent];
            break;

        case NSScrollWheel:
            [self sendScrollEvent:theEvent];
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

                // now, we still want to pass on events to the window, since it
                // does some magic, but we should omit any Velvet-hosted NSViews
                // from consideration
                [(id)self.contentView setUserInteractionEnabled:NO];
                [super sendEvent:theEvent];
                [(id)self.contentView setUserInteractionEnabled:YES];

                // don't fall through
                break;
            }
        }

        // Fall through to here when the first responder isn't a VELView
        default:
            [super sendEvent:theEvent];
    }
}

- (id)bridgedHitTest:(CGPoint)windowPoint; {
    NSAssert([self.contentView isKindOfClass:[NSVelvetView class]], @"Window %@ does not have an NSVelvetView as its content view", self);

    id velvetView = [(id)self.contentView rootView];
    while (YES) {
        if ([velvetView isKindOfClass:[VELNSView class]]) {
            NSView *nsView = [velvetView NSView];

            NSPoint viewPoint = NSPointFromCGPoint([[nsView superview] convertFromWindowPoint:windowPoint]);
            id testView = [nsView hitTest:viewPoint];

            if (![testView isKindOfClass:[NSVelvetView class]]) {
                if (testView)
                    return testView;
                else
                    return nsView;
            }

            NSVelvetView *hostView = testView;
            velvetView = hostView.rootView;
        } else {
            CGPoint viewPoint = [velvetView convertFromWindowPoint:windowPoint];
            id testView = [velvetView hitTest:viewPoint];

            if (![testView isKindOfClass:[VELNSView class]]) {
                if (testView)
                    return testView;
                else
                    return velvetView;
            }

            velvetView = testView;
        }
    }
}

- (void)sendHitTestedEvent:(NSEvent *)event {
    NSVelvetView *contentView = (id)self.contentView;
    CGPoint windowPoint = NSPointToCGPoint([event locationInWindow]);
    id hitView = [self bridgedHitTest:windowPoint];

    if ([hitView isKindOfClass:[VELView class]]) {
        [self dispatchEvent:event toResponder:hitView];
        [self makeFirstResponder:hitView];

        // now, we still want to pass on events to the window, since it
        // does some magic, but we should omit any Velvet-hosted NSViews
        // from consideration
        contentView.userInteractionEnabled = NO;
    }

    // also pass the event upward if we hit an NSView
    [super sendEvent:event];

    contentView.userInteractionEnabled = YES;
}

- (void)sendScrollEvent:(NSEvent *)event; {
    CGPoint windowPoint = NSPointToCGPoint([event locationInWindow]);
    id hitView = [self bridgedHitTest:windowPoint];

    id scrollView = [hitView ancestorScrollView];
    if ([scrollView isKindOfClass:[VELView class]]) {
        [self dispatchEvent:event toResponder:scrollView];
    } else {
        [super sendEvent:event];
    }
}

@end
