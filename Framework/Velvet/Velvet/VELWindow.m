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
#import "VELNSView.h"

@implementation VELWindow

- (void)sendEvent:(NSEvent *)theEvent {
    NSLog(@"theEvent: %@",theEvent);
    
    NSAssert([self.contentView isKindOfClass:[NSVelvetView class]], @"ERROR! Window: %@ does not have a NSVelvetView as it's content view!",self.contentView);
    
    NSVelvetView *velvetView = (NSVelvetView *)self.contentView;
    
    if ([theEvent type] <= NSLeftMouseDown && [theEvent type] <= NSRightMouseUp) {
        VELView *vView = velvetView.rootView;
        id testView = nil;
        BOOL done = NO;
        do {
            if ([vView isKindOfClass:[VELNSView class]]) {
                NSView *nView = ((VELNSView *)vView).NSView;
                testView = [nView hitTest:[self.contentView convertPoint:[theEvent locationInWindow] fromView:nil]];
                if ([[testView superview] isKindOfClass:[NSVelvetView class]]) {
                    vView = ((NSVelvetView *)[testView superview]).rootView;
                }
                else {
                    done = YES;
                }
            }
            else {
                // this assumes that contentView's frame is equal to the rootView's frame
                NSPoint p = [self.contentView convertPoint:[theEvent locationInWindow] fromView:nil];
                p = [vView convertPoint:p fromView:velvetView.rootView];
                testView = [vView hitTest:p];
                if ([testView isKindOfClass:[VELNSView class]]) {
                    vView = testView;
                }
                else {
                    done = YES;
                }
            }
        } while (!done);
        
        if ([testView isKindOfClass:[NSView class]]) {
            [super sendEvent:theEvent];
        }
        else {        
            if ([theEvent type] == NSLeftMouseDown) {
                [testView mouseDown:theEvent];
            }
            else
                if ([theEvent type] == NSLeftMouseUp) {
                [testView mouseUp:theEvent];
            }
        }
    }
}

@end
