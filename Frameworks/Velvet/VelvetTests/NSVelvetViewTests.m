//
//  NSVelvetViewTests.m
//  Velvet
//
//  Created by Josh Vera on 1/6/12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSVelvetViewTests.h"

#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>
#import <Velvet/VELViewProtected.h>


@interface TestVELView : VELView
@end

@implementation NSVelvetViewTests

- (void)testSettingGuestViewOnNSVelvetView {
    VELWindow *window = [[VELWindow alloc]
        initWithContentRect:CGRectMake(100, 100, 500, 500)
        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
        screen:nil
    ];

    TestVELView *containerView = [[TestVELView alloc] init];
    window.contentView.guestView = containerView;

    STAssertEqualObjects(window.contentView.guestView, containerView, @"");
}

@end


@implementation TestVELView

- (void)didMoveFromNSVelvetView:(NSVelvetView *)view {
    [super didMoveFromNSVelvetView:view];
    
    // The NSVelvetView's guestView should be self.
    NSAssert(self.ancestorNSVelvetView.guestView == self, @"");
}

@end
