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

- (void)testSettingTheRootViewOnNSVelvetView {
    VELWindow *window = [[VELWindow alloc]
        initWithContentRect:CGRectMake(100, 100, 500, 500)
        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
        screen:nil
    ];

    NSVelvetView *contentView = [[NSVelvetView alloc] init];
    window.contentView = contentView;

    TestVELView *containerView = [[TestVELView alloc] init];

    contentView.rootView = containerView;

    STAssertEqualObjects(contentView.rootView, containerView, @"");
}

@end


@implementation TestVELView

- (void)didMoveFromHostView:(NSVelvetView *)oldHostView {
    [super didMoveFromHostView:oldHostView];
    
    // The hostView's rootView should be self.
    NSAssert(self.hostView.rootView == self, @"");
}

@end
