//
//  NSWindow+EventHandlingAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Emerald Lark. All rights reserved.
//

#import <Velvet/NSWindow+EventHandlingAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSVelvetViewPrivate.h>
#import <Velvet/NSView+ScrollViewAdditions.h>
#import <Velvet/NSView+VELBridgedViewAdditions.h>
#import <Velvet/VELNSView.h>
#import <Velvet/VELView.h>
#import <Proton/Proton.h>

@safecategory (NSWindow, EventHandlingAdditions)
- (id)bridgedHitTest:(CGPoint)windowPoint; {
    NSAssert([self.contentView isKindOfClass:[NSVelvetView class]], @"Window %@ does not have an NSVelvetView as its content view", self);

    id velvetView = self.rootView;

    CGPoint viewPoint = [velvetView convertFromWindowPoint:windowPoint];
    if (!CGRectContainsPoint(self.rootView.bounds, viewPoint)) {
        return nil;
    }
    
    while (YES) {
        if ([velvetView isKindOfClass:[VELNSView class]]) {
            NSView *nsView = [(id)velvetView NSView];

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

            if (![velvetView isUserInteractionEnabled]) {
                return hostView;
            }
        } else {
            CGPoint viewPoint = [velvetView convertFromWindowPoint:windowPoint];
            id testView = [velvetView descendantViewAtPoint:viewPoint];

            if ([testView isKindOfClass:[VELView class]]) {
                while (testView && ![testView isUserInteractionEnabled]) {
                    testView = [testView superview];
                }
            }

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

- (VELView *)velvetViewForMouseDownEvent:(NSEvent *)event {
    NSAssert([self.contentView isKindOfClass:[NSVelvetView class]], @"Window %@ does not have an NSVelvetView as its content view", self);

    NSVelvetView *contentView = (id)self.contentView;
    
    // we currently do not support any click-through events when the window is
    // not already key
    if ([self isKeyWindow]) {
        CGPoint windowPoint = NSPointToCGPoint([event locationInWindow]);
        
        if ([[[contentView superview] hitTest:windowPoint] isKindOfClass:NSClassFromString(@"NSThemeFrame")]) {
            return nil;
        }
        
        id hitView = [self bridgedHitTest:windowPoint];
        if ([hitView isKindOfClass:[VELView class]]) {
            return hitView;
        }
    }

    return nil;
}

- (VELView *)velvetViewForScrollEvent:(NSEvent *)event; {
    CGPoint windowPoint = NSPointToCGPoint([event locationInWindow]);
    id hitView = [self bridgedHitTest:windowPoint];

    id scrollView = [hitView ancestorScrollView];
    if ([scrollView isKindOfClass:[VELView class]]) {
        return scrollView;
    } else {
        return nil;
    }
}
@end
