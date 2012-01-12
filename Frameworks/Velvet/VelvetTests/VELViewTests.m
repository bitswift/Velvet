//
//  VELViewTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 08.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELViewTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@interface TestView : VELView
@property (nonatomic, assign) BOOL willMoveToSuperviewInvoked;
@property (nonatomic, assign) BOOL willMoveToWindowInvoked;
@property (nonatomic, assign) BOOL didMoveFromSuperviewInvoked;
@property (nonatomic, assign) BOOL didMoveFromWindowInvoked;
@property (nonatomic, unsafe_unretained) VELView *oldSuperview;
@property (nonatomic, unsafe_unretained) VELView *nextSuperview;
@property (nonatomic, unsafe_unretained) VELWindow *oldWindow;
@property (nonatomic, unsafe_unretained) VELWindow *nextWindow;
@property (nonatomic, assign) CGRect drawRectRegion;
@property (nonatomic, assign) BOOL layoutSubviewsInvoked;

- (void)reset;
@end

@interface VELViewTests ()
@property (nonatomic, strong, readonly) VELWindow *window;

- (VELWindow *)newWindow;
@end

@implementation VELViewTests
@synthesize window = m_window;

- (void)setUp {
    m_window = [self newWindow];
}

- (VELWindow *)newWindow {
    return [[VELWindow alloc]
        initWithContentRect:CGRectMake(100, 100, 500, 500)
        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
        screen:nil
    ];
}

- (void)testSizeThatFits {
    VELView *view = [[VELView alloc] init];
    STAssertNotNil(view, @"");

    VELView *subview = [[VELView alloc] initWithFrame:CGRectMake(100, 0, 300, 200)];
    STAssertNotNil(subview, @"");

    [view addSubview:subview];
    [view centeredSizeToFit];

    STAssertEqualsWithAccuracy(view.bounds.size.width, (CGFloat)400, 0.001, @"");
    STAssertEqualsWithAccuracy(view.bounds.size.height, (CGFloat)200, 0.001, @"");
}

- (void)testRemoveFromSuperview {
    VELView *view = [[VELView alloc] init];
    VELView *subview = [[VELView alloc] init];

    [view addSubview:subview];
    STAssertEqualObjects([subview superview], view, @"");
    STAssertEqualObjects([[view subviews] lastObject], subview, @"");

    [subview removeFromSuperview];
    STAssertNil([subview superview], @"");
    STAssertEquals([[view subviews] count], (NSUInteger)0, @"");
}

- (void)testSetSubviews {
    VELView *view = [[VELView alloc] init];

    NSMutableArray *subviews = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0;i < 4;++i) {
        [subviews addObject:[[VELView alloc] init]];
    }

    // make sure that -setSubviews: does not throw an exception
    // (such as mutation while enumerating)
    STAssertNoThrow(view.subviews = subviews, @"");

    // the two arrays should have the same objects, but should not be the same
    // array instance
    STAssertFalse(view.subviews == subviews, @"");
    STAssertEqualObjects(view.subviews, subviews, @"");

    // removing the last subview should remove the last object from the subviews
    // array
    [[subviews lastObject] removeFromSuperview];
    [subviews removeLastObject];

    STAssertEqualObjects(view.subviews, subviews, @"");

    [subviews exchangeObjectAtIndex:0 withObjectAtIndex:2];

    // calling -setSubviews: with a new array should replace the old one
    view.subviews = subviews;
    STAssertEqualObjects(view.subviews, subviews, @"");
}

- (void)testSubclassInitialization {
    TestView *view = [[TestView alloc] init];
    STAssertNotNil(view, @"");
}

- (void)testMovingToSuperview {
    VELView *superview = [[VELView alloc] init];
    TestView *testView = [[TestView alloc] init];

    testView.nextSuperview = superview;

    [superview addSubview:testView];

    STAssertTrue(testView.willMoveToSuperviewInvoked, @"");
    STAssertTrue(testView.didMoveFromSuperviewInvoked, @"");
    STAssertFalse(testView.willMoveToWindowInvoked, @"");
    STAssertFalse(testView.didMoveFromWindowInvoked, @"");
}

- (void)testMovingAcrossSuperviews {
    TestView *testView = [[TestView alloc] init];

    VELView *firstSuperview = [[VELView alloc] init];
    testView.nextSuperview = firstSuperview;
    [firstSuperview addSubview:testView];

    VELView *secondSuperview = [[VELView alloc] init];

    // reset everything for the crossing over test
    [testView reset];

    testView.oldSuperview = firstSuperview;
    testView.nextSuperview = secondSuperview;

    [secondSuperview addSubview:testView];

    STAssertTrue(testView.willMoveToSuperviewInvoked, @"");
    STAssertTrue(testView.didMoveFromSuperviewInvoked, @"");
    STAssertFalse(testView.willMoveToWindowInvoked, @"");
    STAssertFalse(testView.didMoveFromWindowInvoked, @"");
}

- (void)testMovingAcrossWindows {
    TestView *testView = [[TestView alloc] init];
    VELWindow *firstWindow = [self newWindow];
    VELWindow *secondWindow = [self newWindow];

    testView.nextWindow = firstWindow;
    testView.nextSuperview = firstWindow.rootView;

    [firstWindow.rootView addSubview:testView];

    // reset everything for the crossing over test
    [testView reset];

    testView.oldWindow = firstWindow;
    testView.oldSuperview = firstWindow.rootView;
    testView.nextWindow = secondWindow;
    testView.nextSuperview = secondWindow.rootView;

    [secondWindow.rootView addSubview:testView];

    STAssertTrue(testView.willMoveToWindowInvoked, @"");
    STAssertTrue(testView.didMoveFromWindowInvoked, @"");
    STAssertTrue(testView.willMoveToWindowInvoked, @"");
    STAssertTrue(testView.didMoveFromWindowInvoked, @"");
}

- (void)testMovingToWindowViaSuperview {
    TestView *testView = [[TestView alloc] init];

    testView.nextSuperview = self.window.rootView;
    testView.nextWindow = self.window;

    [self.window.rootView addSubview:testView];

    STAssertTrue(testView.willMoveToSuperviewInvoked, @"");
    STAssertTrue(testView.didMoveFromSuperviewInvoked, @"");
    STAssertTrue(testView.willMoveToWindowInvoked, @"");
    STAssertTrue(testView.didMoveFromWindowInvoked, @"");
}

- (void)testMovingToWindowAsRootView {
    TestView *testView = [[TestView alloc] init];

    testView.nextWindow = self.window;
    self.window.contentView.guestView = testView;

    STAssertFalse(testView.willMoveToSuperviewInvoked, @"");
    STAssertFalse(testView.didMoveFromSuperviewInvoked, @"");
    STAssertTrue(testView.willMoveToWindowInvoked, @"");
    STAssertTrue(testView.didMoveFromWindowInvoked, @"");
}

- (void)testResponderChainWithoutSuperviewOrHostView {
    VELView *view = [[VELView alloc] init];

    // a view's next responder should be nil by default
    STAssertNil(view.nextResponder, @"");
}

- (void)testResponderChainWithSuperview {
    VELView *view = [[VELView alloc] init];

    VELView *superview = [[VELView alloc] init];
    [superview addSubview:view];

    // the view's next responder should be the superview
    STAssertEquals(view.nextResponder, superview, @"");
}

- (void)testResponderChainWithHostView {
    VELView *view = [[VELView alloc] init];

    NSVelvetView *hostView = self.window.contentView;
    hostView.guestView = view;

    // the view's next responder should be the host view
    STAssertEquals(view.nextResponder, hostView, @"");
}

- (void)testResponderChainWithSuperviewAndHostView {
    VELView *view = [[VELView alloc] init];

    [self.window.rootView addSubview:view];

    // the view's next responder should be the superview, not the host view
    STAssertEquals(view.nextResponder, self.window.rootView, @"");
}

- (void)testPointInside {
    VELView *view = [[VELView alloc] init];
    view.frame = CGRectMake(0, 0, 50, 50);

    STAssertTrue([view pointInside:CGPointMake(25, 25)], @"");
    STAssertFalse([view pointInside:CGPointMake(-1, -1)], @"");
    STAssertFalse([view pointInside:CGPointMake(50, 50)], @"");
    STAssertTrue([view pointInside:CGPointMake(49, 49)], @"");
}

- (void)testFullyFlexibleAutoresizingMask {
    VELView *superview = [[VELView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    VELView *view = [[VELView alloc] initWithFrame:CGRectMake(20, 20, 60, 60)];
    [superview addSubview:view];

    view.autoresizingMask = VELViewAutoresizingFlexibleLeftMargin | VELViewAutoresizingFlexibleRightMargin | VELViewAutoresizingFlexibleTopMargin | VELViewAutoresizingFlexibleBottomMargin;

    superview.frame = CGRectMake(0, 0, 1000, 1000);

    // force a layout
    [superview.layer setNeedsLayout];
    [superview.layer layoutIfNeeded];

    CGRect expectedFrame = CGRectMake(470, 470, 60, 60);
    STAssertTrue(CGRectEqualToRect(view.frame, expectedFrame), @"");
}

- (void)testOnlyDrawingDirtyRegion {
    TestView *view = [[TestView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [view.layer displayIfNeeded];

    CGRect invalidatedRegion = CGRectMake(10, 10, 25, 25);
    [view setNeedsDisplayInRect:invalidatedRegion];
    [view.layer displayIfNeeded];

    // make sure that -drawRect: was called only with the rectangle we
    // invalidated
    STAssertTrue(CGRectEqualToRect(view.drawRectRegion, invalidatedRegion), @"");
}

- (void)testSettingFrameDoesCallLayoutSubviews {
    TestView *view = [[TestView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    // Even if layoutSubviews is called on init, we clear side effects here.
    [view reset];
    
    view.frame = CGRectMake(10, 10, 25, 25);
    STAssertTrue(view.layoutSubviewsInvoked, @"");
}

- (void)testSettingBoundsDoesCallLayoutSubviews {
    TestView *view = [[TestView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    
    // Even if layoutSubviews is called on init, we clear side effects here.
    [view reset];
    
    view.bounds = CGRectMake(0, 0, 25, 25);
    STAssertTrue(view.layoutSubviewsInvoked, @"");
}

@end

@implementation TestView
@synthesize willMoveToSuperviewInvoked;
@synthesize willMoveToWindowInvoked;
@synthesize didMoveFromSuperviewInvoked;
@synthesize didMoveFromWindowInvoked;
@synthesize oldSuperview = m_oldSuperview;
@synthesize oldWindow = m_oldWindow;
@synthesize nextSuperview;
@synthesize nextWindow;
@synthesize drawRectRegion = m_drawRectRegion;
@synthesize layoutSubviewsInvoked = m_layoutSubviewsInvoked;

- (void)willMoveToSuperview:(VELView *)superview {
    [super willMoveToSuperview:superview];

    NSAssert(self.superview != superview, @"");
    NSAssert(self.superview == self.oldSuperview, @"");
    NSAssert(superview == self.nextSuperview, @"");

    NSAssert(!self.willMoveToSuperviewInvoked, @"");
    NSAssert(!self.didMoveFromSuperviewInvoked, @"");

    self.willMoveToSuperviewInvoked = YES;
}

- (void)didMoveFromSuperview:(VELView *)oldSuperview {
    [super didMoveFromSuperview:oldSuperview];

    NSAssert(self.superview != oldSuperview, @"");
    NSAssert(self.superview == self.nextSuperview, @"");
    NSAssert(oldSuperview == self.oldSuperview, @"");

    NSAssert(self.willMoveToSuperviewInvoked, @"");
    NSAssert(!self.didMoveFromSuperviewInvoked, @"");

    self.didMoveFromSuperviewInvoked = YES;
}

- (void)willMoveToWindow:(NSWindow *)window {
    [super willMoveToWindow:window];

    NSAssert(self.window != window, @"");
    NSAssert(self.window == self.oldWindow, @"");
    NSAssert(window == self.nextWindow, @"");

    NSAssert(!self.willMoveToWindowInvoked, @"");
    NSAssert(!self.didMoveFromWindowInvoked, @"");

    self.willMoveToWindowInvoked = YES;
}

- (void)didMoveFromWindow:(NSWindow *)oldWindow {
    [super didMoveFromWindow:oldWindow];

    NSAssert(self.window != oldWindow, @"");
    NSAssert(self.window == self.nextWindow, @"");
    NSAssert(oldWindow == self.oldWindow, @"");

    NSAssert(self.willMoveToWindowInvoked, @"");
    NSAssert(!self.didMoveFromWindowInvoked, @"");

    self.didMoveFromWindowInvoked = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layoutSubviewsInvoked = YES;
}

- (void)drawRect:(CGRect)rect {
    self.drawRectRegion = rect;
}

- (void)reset; {
    self.willMoveToSuperviewInvoked = NO;
    self.willMoveToWindowInvoked = NO;
    self.didMoveFromSuperviewInvoked = NO;
    self.didMoveFromWindowInvoked = NO;
    self.oldSuperview = nil;
    self.oldWindow = nil;
    self.nextSuperview = nil;
    self.nextWindow = nil;
    self.drawRectRegion = CGRectNull;
    self.layoutSubviewsInvoked = NO;
}

@end
