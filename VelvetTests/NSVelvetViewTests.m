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

@interface TestVELView : VELView
@end

@interface NSVelvetViewTests ()
@property (nonatomic, strong) VELWindow *window;
@end

@implementation NSVelvetViewTests
@synthesize window = m_window;

- (void)setUp {
    self.window = [[VELWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 500)];
}

- (void)tearDown {
    self.window = nil;
}

- (void)testSettingGuestViewOnNSVelvetView {
    TestVELView *containerView = [[TestVELView alloc] init];
    self.window.contentView.guestView = containerView;

    STAssertEqualObjects(self.window.contentView.guestView, containerView, @"");
}

- (void)testResponderChain {
    STAssertEquals(self.window.rootView.nextResponder, self.window.contentView, @"");

    VELView *view = [[VELView alloc] init];
    self.window.rootView = view;

    STAssertEquals(view.nextResponder, self.window.contentView, @"");
    STAssertEquals(self.window.contentView.nextResponder, self.window, @"");
}

- (void)testConformsToVELBridgedView {
    STAssertTrue([NSVelvetView conformsToProtocol:@protocol(VELBridgedView)], @"");

    NSVelvetView *view = [[NSVelvetView alloc] initWithFrame:CGRectZero];
    STAssertTrue([view conformsToProtocol:@protocol(VELBridgedView)], @"");
}

- (void)testConformsToVELHostView {
    STAssertTrue([NSVelvetView conformsToProtocol:@protocol(VELHostView)], @"");

    NSVelvetView *view = [[NSVelvetView alloc] initWithFrame:CGRectZero];
    STAssertTrue([view conformsToProtocol:@protocol(VELHostView)], @"");
}

- (void)testAncestorNSVelvetView {
    NSVelvetView *view = [[NSVelvetView alloc] initWithFrame:CGRectZero];
    STAssertEquals(view.ancestorNSVelvetView, view, @"");
}

- (void)testDescendantViewAtPoint {
    NSVelvetView *velvetView = self.window.contentView;

    VELView *view = [[VELView alloc] initWithFrame:CGRectMake(50, 30, 100, 150)];
    [velvetView.guestView addSubview:view];

    CGPoint guestSubviewPoint = CGPointMake(51, 31);
    STAssertEquals([velvetView descendantViewAtPoint:guestSubviewPoint], view, @"");

    CGPoint guestViewPoint = CGPointMake(49, 29);
    STAssertEquals([velvetView descendantViewAtPoint:guestViewPoint], velvetView.guestView, @"");

    CGPoint outsidePoint = CGPointMake(49, 1000);
    STAssertNil([velvetView descendantViewAtPoint:outsidePoint], @"");
}

@end

@implementation TestVELView

- (void)didMoveFromNSVelvetView:(NSVelvetView *)view {
    [super didMoveFromNSVelvetView:view];
    
    // The NSVelvetView's guestView should be self.
    NSAssert(self.ancestorNSVelvetView.guestView == self, @"");
}

@end
