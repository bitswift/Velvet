//
//  NSWindow+EventHandlingAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSWindow+EventHandlingAdditions.h"
#import "NSVelvetView.h"
#import "NSVelvetViewPrivate.h"
#import "NSView+VELBridgedViewAdditions.h"
#import "VELNSView.h"
#import "VELView.h"
#import "EXTSafeCategory.h"

@safecategory (NSWindow, EventHandlingAdditions)
- (id<VELBridgedView>)bridgedHitTest:(CGPoint)windowPoint; {
    NSView *nsView = self.contentView;

    if (![self isKeyWindow]) {
        // we currently do not support any click-through events when the window is
        // not already key
        return nil;
    }

    NSView *frameHitTestedView = [[nsView superview] hitTest:windowPoint];
    if ([frameHitTestedView isKindOfClass:NSClassFromString(@"NSThemeFrame")]) {
        // ignore clicks on the frame that should trigger window resizing/moving
        return nil;
    }

    while (nsView) {
        CGPoint viewPoint = [[nsView superview] convertFromWindowPoint:windowPoint];
        id testView = [nsView hitTest:viewPoint];

        if (![testView isKindOfClass:[NSVelvetView class]]) {
            return testView;
        }

        NSVelvetView *hostView = testView;
        VELView *velvetView = hostView.guestView;
        
        viewPoint = [velvetView convertFromWindowPoint:windowPoint];
        testView = [velvetView descendantViewAtPoint:viewPoint];

        if ([testView isKindOfClass:[VELNSView class]]) {
            nsView = [(VELNSView *)testView guestView];
        } else {
            return testView;
        }
    }

    return nil;
}

@end
