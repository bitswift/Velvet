//
//  NSWindow+EventHandlingAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/NSWindow+EventHandlingAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSVelvetViewPrivate.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/VELNSView.h>
#import <Velvet/VELView.h>
#import <Proton/Proton.h>

@safecategory (NSWindow, EventHandlingAdditions)
- (id<VELBridgedView>)bridgedHitTest:(CGPoint)windowPoint; {
    NSView *nsView = self.contentView;

    while (nsView) {
        CGPoint viewPoint = [[nsView superview] convertFromWindowPoint:windowPoint];
        id testView = [nsView hitTest:viewPoint];

        if (![testView isKindOfClass:[NSVelvetView class]]) {
            break;
        }

        NSVelvetView *hostView = testView;
        VELView *velvetView = hostView.guestView;

        if (![velvetView isUserInteractionEnabled]) {
            break;
        }
        
        viewPoint = [velvetView convertFromWindowPoint:windowPoint];
        testView = [velvetView descendantViewAtPoint:viewPoint];

        // TODO: make this more general, to support all bridged views
        if ([testView isKindOfClass:[VELView class]]) {
            while (testView && ![testView isUserInteractionEnabled]) {
                testView = [testView superview];
            }
        }

        if ([testView isKindOfClass:[VELNSView class]]) {
            nsView = [(VELNSView *)testView guestView];
        } else {
            return testView;
        }
    }

    return nil;
}

- (id<VELBridgedView>)bridgedViewForMouseDownEvent:(NSEvent *)event {
    id contentView = self.contentView;
    
    // we currently do not support any click-through events when the window is
    // not already key
    if ([self isKeyWindow]) {
        CGPoint windowPoint = NSPointToCGPoint([event locationInWindow]);
        
        if ([[[contentView superview] hitTest:windowPoint] isKindOfClass:NSClassFromString(@"NSThemeFrame")]) {
            return nil;
        }
        
        id hitView = [self bridgedHitTest:windowPoint];
        if (![hitView isKindOfClass:[NSView class]]) {
            return hitView;
        }
    }

    return nil;
}

- (id<VELBridgedView>)bridgedViewForScrollEvent:(NSEvent *)event; {
    CGPoint windowPoint = NSPointToCGPoint([event locationInWindow]);
    id hitView = [self bridgedHitTest:windowPoint];

    id scrollView = [hitView ancestorScrollView];
    if (![scrollView isKindOfClass:[NSView class]]) {
        return scrollView;
    } else {
        return nil;
    }
}
@end
