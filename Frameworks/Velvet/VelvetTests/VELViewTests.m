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
#import <Proton/Proton.h>

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

- (void)testInitialization {
    VELView *view = [[VELView alloc] init];
    STAssertNotNil(view, @"");

    STAssertTrue(view.alignsToIntegralPixels, @"");
    STAssertTrue(view.clearsContextBeforeDrawing, @"");
    STAssertEquals(view.contentMode, VELViewContentModeScaleToFill, @"");
    STAssertFalse(view.hidden, @"");
    STAssertNil(view.hostView, @"");
    STAssertNotNil(view.layer, @"");
    STAssertFalse(view.opaque, @"");
    STAssertNil(view.superview, @"");
    STAssertTrue(view.userInteractionEnabled, @"");
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

- (void)testAlignsToIntegralPointsSettingFrame {
    VELView *view = [[VELView alloc] init];

    view.frame = CGRectMake(10.25, 11.5, 12.75, 13.01);

    CGRect expectedFrame = CGRectMake(10, 12, 12, 13);
    STAssertTrue(CGRectEqualToRect(view.frame, expectedFrame), @"frame %@ does not match expected %@", NSStringFromRect(view.frame), NSStringFromRect(expectedFrame));
}

- (void)testAlignsToIntegralPointsSettingBounds {
    VELView *view = [[VELView alloc] init];

    view.bounds = CGRectMake(0, 0, 12.75, 13.01);

    CGRect expectedBounds = CGRectMake(0, 0, 12, 13);
    STAssertTrue(CGRectEqualToRect(view.bounds, expectedBounds), @"");
}

- (void)testAlignsToIntegralPointsSettingMisalignedCenter {
    VELView *view = [[VELView alloc] init];

    view.center = CGPointMake(13.7, 14.3);

    CGPoint expectedCenter = CGPointMake(13, 15);
    STAssertTrue(CGPointEqualToPoint(view.center, expectedCenter), @"");
}

- (void)testAlignsToIntegralPointsSettingCenterResultingInMisalignedFrame {
    VELView *view = [[VELView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];

    view.center = CGPointMake(15, 15);

    CGRect expectedFrame = CGRectMake(12, 13, 5, 5);
    STAssertTrue(CGRectEqualToRect(view.frame, expectedFrame), @"");
}

- (void)testAlignsToIntegralPointsWhenAutoresizing {
    VELView *superview = [[VELView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];

    VELView *subview = [[VELView alloc] initWithFrame:CGRectMake(5, 5, 20, 20)];
    subview.autoresizingMask = VELViewAutoresizingFlexibleMargins;
    [superview addSubview:subview];

    superview.frame = CGRectMake(0, 0, 25, 25);

    CGRect expectedSubviewFrame = CGRectMake(2, 3, 20, 20);
    STAssertTrue(CGRectEqualToRect(subview.frame, expectedSubviewFrame), @"subview frame %@ does not match expected %@", NSStringFromRect(subview.frame), NSStringFromRect(expectedSubviewFrame));
}

- (void)testSuperviewKVO {
    VELView *subview = [[VELView alloc] init];

    @autoreleasepool {
        __block BOOL notificationReceived = NO;

        PROKeyValueObserver *observer = [[PROKeyValueObserver alloc]
            initWithTarget:subview
            keyPath:PROKeyForObject(subview, superview)
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
            block:^(NSDictionary *changes){
                id newValue = [changes objectForKey:NSKeyValueChangeNewKey];
                if ([newValue isEqual:[NSNull null]])
                    newValue = nil;

                STAssertEquals(newValue, subview.superview, @"");

                id oldValue = [changes objectForKey:NSKeyValueChangeOldKey];
                if ([oldValue isEqual:[NSNull null]])
                    oldValue = nil;

                STAssertTrue(oldValue != subview.superview, @"");

                notificationReceived = YES;
            }
        ];

        // Clang, shut up
        [observer self];

        [[[VELView alloc] init] addSubview:subview];

        STAssertTrue(notificationReceived, @"");
        notificationReceived = NO;

        [subview removeFromSuperview];

        STAssertTrue(notificationReceived, @"");
    }
}

- (void)testSubviewsReplacementKVO {
    VELView *superview = [[VELView alloc] init];

    @autoreleasepool {
        __block BOOL notificationReceived = NO;

        PROKeyValueObserver *observer = [[PROKeyValueObserver alloc]
            initWithTarget:superview
            keyPath:PROKeyForObject(superview, subviews)
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
            block:^(NSDictionary *changes){
                STAssertTrue(NSKeyValueChangeSetting == [[changes objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue], @"");

                id newValue = [changes objectForKey:NSKeyValueChangeNewKey];
                if ([newValue isEqual:[NSNull null]])
                    newValue = nil;

                STAssertEqualObjects(newValue, superview.subviews, @"");

                id oldValue = [changes objectForKey:NSKeyValueChangeOldKey];
                if ([oldValue isEqual:[NSNull null]])
                    oldValue = nil;

                STAssertFalse([oldValue isEqualToArray:superview.subviews], @"");

                notificationReceived = YES;
            }
        ];

        // Clang, shut up
        [observer self];

        superview.subviews = [NSArray arrayWithObjects:[[VELView alloc] init], [[VELView alloc] init], nil];

        STAssertTrue(notificationReceived, @"");
        notificationReceived = NO;

        superview.subviews = nil;

        STAssertTrue(notificationReceived, @"");
    }
}

- (void)testSubviewsInsertionKVO {
    VELView *superview = [[VELView alloc] init];

    @autoreleasepool {
        __block BOOL notificationReceived = NO;

        PROKeyValueObserver *observer = [[PROKeyValueObserver alloc]
            initWithTarget:superview
            keyPath:PROKeyForObject(superview, subviews)
            options:NSKeyValueObservingOptionNew
            block:^(NSDictionary *changes){
                STAssertTrue(NSKeyValueChangeInsertion == [[changes objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue], @"");

                NSArray *values = [changes objectForKey:NSKeyValueChangeNewKey];
                NSIndexSet *indexes = [changes objectForKey:NSKeyValueChangeIndexesKey];
                STAssertEqualObjects([superview.subviews objectsAtIndexes:indexes], values, @"");

                notificationReceived = YES;
            }
        ];

        // Clang, shut up
        [observer self];

        [superview addSubview:[[VELView alloc] init]];

        STAssertTrue(notificationReceived, @"");
    }
}

- (void)testSubviewsRemovalKVO {
    VELView *superview = [[VELView alloc] init];

    VELView *subview = [[VELView alloc] init];
    [superview addSubview:subview];

    @autoreleasepool {
        __block BOOL notificationReceived = NO;

        PROKeyValueObserver *observer = [[PROKeyValueObserver alloc]
            initWithTarget:superview
            keyPath:PROKeyForObject(superview, subviews)
            options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior
            block:^(NSDictionary *changes){
                STAssertTrue(NSKeyValueChangeRemoval == [[changes objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue], @"");

                if (![[changes objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue])
                    return;

                NSArray *values = [changes objectForKey:NSKeyValueChangeOldKey];
                NSIndexSet *indexes = [changes objectForKey:NSKeyValueChangeIndexesKey];
                STAssertEqualObjects([superview.subviews objectsAtIndexes:indexes], values, @"");

                notificationReceived = YES;
            }
        ];

        // Clang, shut up
        [observer self];

        [subview removeFromSuperview];

        STAssertTrue(notificationReceived, @"");
    }
}

- (void)testConformsToVELBridgedView {
    STAssertTrue([VELView conformsToProtocol:@protocol(VELBridgedView)], @"");

    VELView *view = [[VELView alloc] init];
    STAssertTrue([view conformsToProtocol:@protocol(VELBridgedView)], @"");
}

- (void)testConvertFromWindowPoint {
    VELView *view = [[VELView alloc] initWithFrame:CGRectMake(50, 100, 100, 200)];
    [self.window.rootView addSubview:view];

    CGPoint windowPoint = CGPointMake(175, 355);
    CGPoint viewPoint = CGPointMake(125, 255);

    STAssertTrue(CGPointEqualToPoint([view convertFromWindowPoint:windowPoint], viewPoint), @"");
}

- (void)testConvertToWindowPoint {
    VELView *view = [[VELView alloc] initWithFrame:CGRectMake(50, 100, 100, 200)];
    [self.window.rootView addSubview:view];

    CGPoint windowPoint = CGPointMake(175, 355);
    CGPoint viewPoint = CGPointMake(125, 255);

    STAssertTrue(CGPointEqualToPoint([view convertToWindowPoint:viewPoint], windowPoint), @"");
}

- (void)testConvertFromWindowRect {
    VELView *view = [[VELView alloc] initWithFrame:CGRectMake(50, 100, 100, 200)];
    [self.window.rootView addSubview:view];

    CGRect windowRect = CGRectMake(175, 355, 100, 100);
    CGRect viewRect = CGRectMake(125, 255, 100, 100);

    STAssertTrue(CGRectEqualToRect([view convertFromWindowRect:windowRect], viewRect), @"");
}

- (void)testConvertToWindowRect {
    VELView *view = [[VELView alloc] initWithFrame:CGRectMake(50, 100, 100, 200)];
    [self.window.rootView addSubview:view];

    CGRect windowRect = CGRectMake(175, 355, 100, 100);
    CGRect viewRect = CGRectMake(125, 255, 100, 100);

    STAssertTrue(CGRectEqualToRect([view convertToWindowRect:viewRect], windowRect), @"");
}

- (void)testLayer {
    VELView *view = [[VELView alloc] init];
    STAssertNotNil(view.layer, @"");
}

- (void)testHostView {
    VELView *view = [[VELView alloc] init];
    STAssertNil(view.hostView, @"");

    self.window.rootView = view;
    STAssertEquals(view.hostView, self.window.contentView, @"");
}

- (void)testAncestorDidLayout {
    VELView *view = [[VELView alloc] init];
    STAssertNoThrow([view ancestorDidLayout], @"");
}

- (void)testAncestorNSVelvetView {
    VELView *view = [[VELView alloc] init];
    [self.window.rootView addSubview:view];

    STAssertEquals(view.ancestorNSVelvetView, self.window.contentView, @"");
}

- (void)testAncestorScrollView {
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];

    NSVelvetView *velvetView = [[NSVelvetView alloc] initWithFrame:CGRectZero];
    [scrollView setDocumentView:velvetView];

    STAssertEquals(velvetView.guestView.ancestorScrollView, scrollView, @"");
}

- (void)testWillMoveToNSVelvetView {
    VELView *view = [[VELView alloc] init];
    STAssertNoThrow([view willMoveToNSVelvetView:nil], @"");
}

- (void)testDidMoveFromNSVelvetView {
    VELView *view = [[VELView alloc] init];
    STAssertNoThrow([view didMoveFromNSVelvetView:nil], @"");
}

- (void)testDescendantViewAtPoint {
    VELView *superview = [[VELView alloc] initWithFrame:CGRectMake(20, 20, 80, 80)];
    [self.window.rootView addSubview:superview];

    VELView *subview = [[VELView alloc] initWithFrame:CGRectMake(50, 30, 100, 150)];
    [superview addSubview:subview];

    CGPoint subviewPoint = CGPointMake(51, 31);
    STAssertEquals([superview descendantViewAtPoint:subviewPoint], subview, @"");

    CGPoint superviewPoint = CGPointMake(49, 29);
    STAssertEquals([superview descendantViewAtPoint:superviewPoint], superview, @"");

    CGPoint outsidePoint = CGPointMake(49, 200);
    STAssertNil([superview descendantViewAtPoint:outsidePoint], @"");
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
