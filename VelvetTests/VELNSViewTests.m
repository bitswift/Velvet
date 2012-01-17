//
//  VELNSViewTests.m
//  Velvet
//
//  Created by James Lawton on 12/12/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELNSViewTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@interface VELNSViewTests ()
@property (nonatomic, strong) VELWindow *window;
@end

@implementation VELNSViewTests
@synthesize window = m_window;

- (void)setUp {
    self.window = [[VELWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 500)];
}

- (void)tearDown {
    self.window = nil;
}

- (void)testResponderChain {
    VELWindow *window = self.window;
    
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

// INTERNAL-226
- (void)testSettingNSViewBeforeHavingSuperview {
    NSView *contained = [[NSView alloc] initWithFrame:CGRectZero];

    VELNSView *view = [[VELNSView alloc] init];
    view.guestView = contained;

    NSVelvetView *hostView = [[NSVelvetView alloc] initWithFrame:CGRectZero];
    [hostView.guestView addSubview:view];

    STAssertTrue([contained.superview isDescendantOf:hostView], @"");
}

// INTERNAL-380
- (void)testNSViewFrameSynchronizesWithVELNSViewFrameChanges {
    VELWindow *window = self.window;

    NSView *hosted = [[NSView alloc] initWithFrame:CGRectZero];
    VELNSView *view = [[VELNSView alloc] initWithNSView:hosted];

    [window.rootView addSubview:view];

    view.frame = CGRectMake(20, 30, 40, 50);
    STAssertTrue(CGRectEqualToRect(view.frame, hosted.frame), @"");
}

// INTERNAL-380
- (void)testNSViewFrameSynchronizesWithVELNSViewCenterChanges {
    VELWindow *window = self.window;

    NSView *hosted = [[NSView alloc] initWithFrame:CGRectZero];
    VELNSView *view = [[VELNSView alloc] initWithNSView:hosted];

    [window.rootView addSubview:view];

    // Change the center and make sure the hosted view's center changes too.
    view.center = CGPointMake(20, 30);
    STAssertTrue(CGRectEqualToRect(view.frame, hosted.frame), @"");
}

- (void)testNSViewFrameOriginSynchronizesWithAncestorFrameChanges {
    VELWindow *window = self.window;
    VELView *supersuperview = [[VELView alloc] initWithFrame:CGRectMake(20, 30, 100, 100)];
    VELView *superview = [[VELView alloc] initWithFrame:CGRectMake(20, 30, 100, 100)];
    NSView *hosted = [[NSView alloc] initWithFrame:CGRectZero];
    VELNSView *view = [[VELNSView alloc] initWithNSView:hosted];
    
    // Create a hierarchy deeper than one level to better test cascade effect.
    [window.rootView addSubview:supersuperview];
    [supersuperview addSubview:superview];
    [superview addSubview:view];

    // Modifying both size and origin of the top level frame should cascade synchronizations down the chain.
    supersuperview.frame = CGRectMake(1, 20, 600, 100);

    // If the hosted frame's origin is the same, the frame change is synchronized.
    CGPoint absoluteViewOrigin = [view convertToWindowPoint:CGPointMake(0, 0)];
    STAssertTrue(CGPointEqualToPoint(hosted.frame.origin, absoluteViewOrigin), @"");
}

- (void)testNSViewFrameOriginSynchronizesWithAncestorFrameOriginChanges {
    VELWindow *window = self.window;
    VELView *supersuperview = [[VELView alloc] initWithFrame:CGRectMake(20, 30, 100, 100)];
    VELView *superview = [[VELView alloc] initWithFrame:CGRectMake(20, 30, 100, 100)];
    NSView *hosted = [[NSView alloc] initWithFrame:CGRectZero];
    VELNSView *view = [[VELNSView alloc] initWithNSView:hosted];
    
    // Create a hierarchy deeper than one level to better test cascade effect.
    [window.rootView addSubview:supersuperview];
    [supersuperview addSubview:superview];
    [superview addSubview:view];
    
    // Remember the hosting NSVelView's origin
    CGPoint originalViewOrigin = view.frame.origin;

    // Trigger a change in the frame way up high.
    supersuperview.frame = CGRectMake(1, 1, 100, 100);
    
    // If the hosted frame's origin is the same as the window's notion of it's origin,
    // then the frame change is correctly synchronized.
    CGPoint absoluteViewOrigin = [view convertToWindowPoint:CGPointMake(0, 0)];
    STAssertTrue(CGPointEqualToPoint(hosted.frame.origin, absoluteViewOrigin), @"");
    
    // Ensure that the hosting view's frame origin hasn't moved.
    STAssertTrue(CGPointEqualToPoint(view.frame.origin, originalViewOrigin), @"");
}

- (void)testNSViewFrameCenterSynchronizesWithAncestorFrameCenterChanges {
    VELWindow *window = self.window;
    VELView *supersuperview = [[VELView alloc] initWithFrame:CGRectMake(20, 30, 100, 100)];
    VELView *superview = [[VELView alloc] initWithFrame:CGRectMake(20, 30, 100, 100)];
    NSView *hosted = [[NSView alloc] initWithFrame:CGRectZero];
    VELNSView *view = [[VELNSView alloc] initWithNSView:hosted];
    
    // Create a hierarchy deeper than one level to better test cascade effect.
    [window.rootView addSubview:supersuperview];
    [supersuperview addSubview:superview];
    [superview addSubview:view];
    
    // Remember the hosting NSVelView's origin
    CGPoint originalViewOrigin = view.frame.origin;
    
    // Trigger a change to the center high in hierarchy.
    supersuperview.center = CGPointMake(42, 42);
    
    // If the hosted frame's origin is the same as the window's notion of it's origin,
    // then the frame change is correctly synchronized.
    CGPoint absoluteViewOrigin = [view convertToWindowPoint:CGPointMake(0, 0)];
    STAssertTrue(CGPointEqualToPoint(hosted.frame.origin, absoluteViewOrigin), @"");
    
    // Ensure that the hosting view's frame origin hasn't moved.
    STAssertTrue(CGPointEqualToPoint(view.frame.origin, originalViewOrigin), @"");
}

- (void)testConformsToVELBridgedView {
    STAssertTrue([VELNSView conformsToProtocol:@protocol(VELBridgedView)], @"");

    VELNSView *view = [[VELNSView alloc] init];
    STAssertTrue([view conformsToProtocol:@protocol(VELBridgedView)], @"");
}

- (void)testConformsToVELHostView {
    STAssertTrue([VELNSView conformsToProtocol:@protocol(VELHostView)], @"");

    VELNSView *view = [[VELNSView alloc] init];
    STAssertTrue([view conformsToProtocol:@protocol(VELHostView)], @"");
}

- (void)testAncestorNSVelvetView {
    VELNSView *view = [[VELNSView alloc] initWithFrame:CGRectZero];
    [self.window.rootView addSubview:view];

    STAssertEquals(view.ancestorNSVelvetView, self.window.contentView, @"");
}

- (void)testDescendantViewAtPoint {
    VELNSView *hostView = [[VELNSView alloc] init];
    self.window.rootView = hostView;

    hostView.guestView = [[NSView alloc] init];

    NSView *view = [[NSView alloc] initWithFrame:CGRectMake(50, 30, 100, 150)];
    [hostView.guestView addSubview:view];

    CGPoint guestSubviewPoint = CGPointMake(51, 31);
    STAssertEquals([hostView descendantViewAtPoint:guestSubviewPoint], view, @"");

    CGPoint guestViewPoint = CGPointMake(49, 29);
    STAssertEquals([hostView descendantViewAtPoint:guestViewPoint], hostView.guestView, @"");

    CGPoint outsidePoint = CGPointMake(49, 1000);
    STAssertNil([hostView descendantViewAtPoint:outsidePoint], @"");
}

- (void)testGuestView {
    VELNSView *hostView = [[VELNSView alloc] init];

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
    hostView.guestView = scrollView;

    STAssertEquals(hostView.guestView, scrollView, @"");
}

@end
