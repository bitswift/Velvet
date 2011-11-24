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
- (void)dispatchEvent:(NSEvent *)event toView:(VELView *)view;
- (void)sendMouseEvent:(NSEvent *)event;
@end

@implementation VELWindow

- (void)dispatchEvent:(NSEvent *)event toView:(VELView *)view; {
    switch ([event type]) {
    case NSLeftMouseDown:
        [view mouseDown:event];
        break;

    case NSLeftMouseUp:
        [view mouseUp:event];
        break;

    case NSRightMouseDown:
        [view rightMouseDown:event];
        break;

    case NSRightMouseUp:
        [view rightMouseUp:event];
        break;

    case NSMouseMoved:
        [view mouseMoved:event];
        break;

    case NSLeftMouseDragged:
        [view mouseDragged:event];
        break;

    case NSRightMouseDragged:
        [view rightMouseDragged:event];
        break;

    case NSMouseEntered:
        [view mouseEntered:event];
        break;

    case NSMouseExited:
        [view mouseExited:event];
        break;

    case NSOtherMouseDown:
        [view otherMouseDown:event];
        break;

    case NSOtherMouseUp:
        [view otherMouseUp:event];
        break;

    case NSOtherMouseDragged:
        [view otherMouseDragged:event];
        break;

    default:
        NSLog(@"Unrecognized event %@", event);
    }
}

- (void)sendEvent:(NSEvent *)theEvent {
    switch ([theEvent type]) {
        case NSLeftMouseDown:
        case NSLeftMouseUp:
        case NSRightMouseDown:
        case NSRightMouseUp:
        case NSMouseMoved:
        case NSLeftMouseDragged:
        case NSRightMouseDragged:
        case NSMouseEntered:
        case NSMouseExited:
        case NSOtherMouseDown:
        case NSOtherMouseUp:
        case NSOtherMouseDragged:   
            [self sendMouseEvent:theEvent];
            break;
        default:
            break;
    }
}

- (void)sendMouseEvent:(NSEvent *)event {
    NSAssert([self.contentView isKindOfClass:[NSVelvetView class]], @"Window %@ does not have an NSVelvetView as its content view", self);
    
    id velvetView = [(id)self.contentView rootView];
    CGPoint windowPoint = NSPointToCGPoint([event locationInWindow]);

    while (YES) {
        if ([velvetView isKindOfClass:[VELNSView class]]) {
            NSView *nsView = [velvetView NSView];

            NSPoint viewPoint = NSPointFromCGPoint([[nsView superview] convertFromWindowPoint:windowPoint]);
            id testView = [nsView hitTest:viewPoint];

            if (![testView isKindOfClass:[NSVelvetHostView class]]) {
                [super sendEvent:event];
                break;
            }

            NSVelvetView *hostView = (id)[testView superview];
            velvetView = hostView.rootView;
        } else {
            id testView = nil;

            if ([velvetView superview]) {
                testView = [velvetView hitTest:[[velvetView superview] convertFromWindowPoint:windowPoint]];
            } else {
                testView = [velvetView hitTest:[[velvetView hostView] convertFromWindowPoint:windowPoint]];
            }

            if (![testView isKindOfClass:[VELNSView class]]) {
                [self dispatchEvent:event toView:testView];
                break;
            }

            velvetView = testView;
        }
    }
}

@end
