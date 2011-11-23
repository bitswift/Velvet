//
//  VELWindow.m
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELWindow.h"
#import "NSVelvetView.h"
#import "VELView.h"
#import "NSView+VELGeometryAdditions.h"
#import "VELNSView.h"

@interface VELWindow ()
- (void)sendMouseEvent:(NSEvent *)theEvent;
@end

@implementation VELWindow

- (void)sendEvent:(NSEvent *)theEvent {
    NSAssert([self.contentView isKindOfClass:[NSVelvetView class]], @"ERROR! Window: %@ does not have a NSVelvetView as it's content view!",self.contentView);
    
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

- (void)sendMouseEvent:(NSEvent *)theEvent {
    VELView *vView = ((NSVelvetView *)self.contentView).rootView;
    id testView = nil;
    CGPoint windowPt = NSPointToCGPoint([theEvent locationInWindow]);
    do {
        if ([vView isKindOfClass:[VELNSView class]]) {
            NSView *nView = ((VELNSView *)vView).NSView;
            testView = [nView hitTest:[[nView superview] convertFromWindowPoint:windowPt]];
            // we need to determine this class better
            if ([[testView className] isEqualToString:@"NSVelvetHostView"]) {
                vView = ((NSVelvetView *)[testView superview]).rootView;
            } else {
                [super sendEvent:theEvent];
                return;
            }
        } else {
            if ([vView superview]) {
                testView = [vView hitTest:[[vView superview] convertFromWindowPoint:windowPt]];
            } else {
                testView = [vView hitTest:[[vView hostView] convertFromWindowPoint:windowPt]];
            }
            if ([testView isKindOfClass:[VELNSView class]]) {
                vView = testView;
            } else {
                if ([theEvent type] == NSLeftMouseDown) {
                    [vView mouseDown:theEvent];
                } else if ([theEvent type] == NSLeftMouseUp) {
                    [vView mouseUp:theEvent];
                } else if ([theEvent type] == NSRightMouseDown) {
                    [vView rightMouseDown:theEvent];
                } else if ([theEvent type] == NSRightMouseUp) {
                    [vView rightMouseUp:theEvent];
                } else if ([theEvent type] == NSMouseMoved) {
                    [vView mouseMoved:theEvent];
                } else if ([theEvent type] == NSLeftMouseDragged) {
                    [vView mouseDragged:theEvent];
                } else if ([theEvent type] == NSRightMouseDragged) {
                    [vView rightMouseDragged:theEvent];
                } else if ([theEvent type] == NSMouseEntered) {
                    [vView mouseEntered:theEvent];
                } else if ([theEvent type] == NSMouseExited) {
                    [vView mouseExited:theEvent];
                } else if ([theEvent type] == NSOtherMouseDown) {
                    [vView otherMouseDown:theEvent];
                } else if ([theEvent type] == NSOtherMouseUp) {
                    [vView otherMouseUp:theEvent];
                } else if ([theEvent type] == NSOtherMouseDragged) {
                    [vView otherMouseDragged:theEvent];
                }
                return;
            }
        }
    } while (YES);
}

@end
