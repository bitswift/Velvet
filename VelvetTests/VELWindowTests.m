//
//  VELWindowTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELWindowTests.h"
#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

@interface VELWindowTests ()
- (VELWindow *)newWindow;
@end

@implementation VELWindowTests

- (VELWindow *)newWindow {
    return [[VELWindow alloc]
        initWithContentRect:CGRectMake(100, 100, 500, 500)
        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
    ];
}

- (void)testInitialization {
    VELWindow *window = [self newWindow];

    STAssertNotNil(window, @"");
}

- (void)testInitializationWithScreen {
    VELWindow *window = [[VELWindow alloc]
        initWithContentRect:CGRectMake(100, 100, 500, 500)
        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
        screen:nil
    ];

    STAssertNotNil(window, @"");
}

- (void)testContentView {
    VELWindow *window = [self newWindow];

    NSVelvetView *hostView = window.contentView;
    STAssertNotNil(hostView, @"");
    STAssertTrue([hostView isKindOfClass:[NSVelvetView class]], @"");
}

- (void)testRootView {
    VELWindow *window = [self newWindow];
    
    VELView *rootView = window.rootView;
    STAssertNotNil(rootView, @"");
    STAssertEquals(rootView.hostView, window.contentView, @"");
}

@end
