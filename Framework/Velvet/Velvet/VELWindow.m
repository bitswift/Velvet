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
        
    if (NSLeftMouseDown <= [theEvent type] && [theEvent type] <= NSRightMouseUp) {
        VELView *vView = ((NSVelvetView *)self.contentView).rootView;
        // this assumes that contentView's frame is equal to the rootView's frame
//        CGPoint viewPt = [theEvent locationInWindow];//[self.contentView convertPoint:[theEvent locationInWindow] fromView:nil];
        id testView = nil;
        do {
            if ([vView isKindOfClass:[VELNSView class]]) {
                NSView *nView = ((VELNSView *)vView).NSView;
                testView = [nView hitTest:[nView convertPoint:[theEvent locationInWindow] fromView:nil]];
                if ([[testView superview] isKindOfClass:[NSVelvetView class]]) {
                    vView = ((NSVelvetView *)[testView superview]).rootView;
                } else {
                    [super sendEvent:theEvent];
                    return;
                }
            } else {
                testView = [vView hitTest:[vView convertPoint:[theEvent locationInWindow] fromView:nil]];
                if ([testView isKindOfClass:[VELNSView class]]) {
                    vView = testView;
                } else {
                    if ([theEvent type] == NSLeftMouseDown) {
                        [testView mouseDown:theEvent];
                    } else if ([theEvent type] == NSLeftMouseUp) {
                        [testView mouseUp:theEvent];
                    }
                    return;
                }
            }
        } while (YES);
    }
}

@end
