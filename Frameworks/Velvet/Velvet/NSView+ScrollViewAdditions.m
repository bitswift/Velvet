//
//  NSView+ScrollViewAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSView+ScrollViewAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/NSView+VELNSViewAdditions.h>
#import <Velvet/VELNSView.h>
#import <Proton/EXTSafeCategory.h>

@safecategory (NSView, ScrollViewAdditions)
- (id)ancestorScrollView; {
    // search ancestors for a Velvet-hosted view
    NSView *view = self;
    do {
        VELNSView *hostView = view.hostView;
        if (hostView) {
            // hand off control, since this might recurse further up the NSView
            // hierarchy
            return [hostView ancestorScrollView];
        }

        if ([view isKindOfClass:[NSScrollView class]])
            return view;

        view = view.superview;
    } while (view);

    return nil;
}

@end
