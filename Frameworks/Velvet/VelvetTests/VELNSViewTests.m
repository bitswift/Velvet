//
//  VELNSViewTests.m
//  Velvet
//
//  Created by James Lawton on 12/12/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELNSViewTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@interface VELNSViewTests ()
- (VELWindow *)newWindow;
@end


@implementation VELNSViewTests

- (VELWindow *)newWindow {
    return [[VELWindow alloc]
        initWithContentRect:CGRectMake(100, 100, 500, 500)
        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
        screen:nil
    ];
}

- (void)testResponderChain {
    // create a container window
    VELWindow *window = [self newWindow];
    
    // Set up a VELNSView
    NSView *contained = [[NSView alloc] initWithFrame:CGRectZero];
    VELNSView *view = [[VELNSView alloc] initWithNSView:contained];

    // Set up a Velvet hierarchy
    [window.rootView addSubview:view];

    // Check that the contained NSView's nextResponder is still the VELNSView, even
    // though its superview has been changed. Check that the VELNSView's nextResponder
    // is now set.
    STAssertEquals(window.rootView, [view nextResponder], @"");
    STAssertEquals(view, [contained nextResponder], @"");
}

@end
