//
//  VELViewControllerTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 21.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELViewControllerTests.h"
#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

// these are static because these methods are only called from
// -[VELViewController dealloc], and we need to make sure that they were
// called after the view controller has been destroyed
static BOOL testViewControllerWillUnloadCalled = NO;
static BOOL testViewControllerDidUnloadCalled = NO;

@interface TestViewController : VELViewController
@property (nonatomic) BOOL viewWillAppearCalled;
@property (nonatomic) BOOL viewDidAppearCalled;
@property (nonatomic) BOOL viewWillDisappearCalled;
@property (nonatomic) BOOL viewDidDisappearCalled;
@end

@interface VELViewControllerTests () {
    /*
     * A window to hold the <visibleView>.
     */
    VELWindow *m_window;
}

/*
 * A view that is guaranteed to be visible on screen, to be used for
 * testing appearance/disappearance of subviews.
 */
@property (nonatomic, strong, readonly) VELView *visibleView;

/*
 * A window that is guaranteed to be visible on screen.
 */
@property (nonatomic, strong, readonly) VELWindow *window;
@end

@implementation VELViewControllerTests
@synthesize window = m_window;

- (VELView *)visibleView {
    return m_window.rootView;
}

- (void)setUp {
    testViewControllerWillUnloadCalled = NO;
    testViewControllerDidUnloadCalled = NO;

    m_window = [[VELWindow alloc]
        initWithContentRect:CGRectMake(100, 100, 500, 500)
        styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
        backing:NSBackingStoreBuffered
        defer:NO
        screen:nil
    ];

    [m_window makeKeyAndOrderFront:nil];
}

- (void)tearDown {
    [m_window close];
}

- (void)testInitialization {
    VELViewController *controller = [[VELViewController alloc] init];
    STAssertNotNil(controller, @"");
    STAssertFalse(controller.viewLoaded, @"");
}

- (void)testImplicitLoadView {
    VELViewController *controller = [[VELViewController alloc] init];

    // using the 'view' property should load it into memory
    VELView *view = controller.view;

    STAssertNotNil(view, @"");
    STAssertTrue(controller.viewLoaded, @"");

    // re-reading the property should return the same view
    STAssertEqualObjects(controller.view, view, @"");
}

- (void)testLoadView {
    VELViewController *controller = [[VELViewController alloc] init];

    VELView *view = [controller loadView];
    STAssertNotNil(view, @"");

    // the view should have zero width and zero height
    STAssertTrue(CGRectEqualToRect(view.bounds, CGRectZero), @"");
}

- (void)testViewUnloading {
    // instantiate a view controller in an explicit autorelease pool to
    // deterministically control when -dealloc is invoked
    @autoreleasepool {
        __autoreleasing TestViewController *vc = [[TestViewController alloc] init];

        // access the view property so that it gets loaded in the first place
        [vc view];
    }

    STAssertTrue(testViewControllerWillUnloadCalled, @"");
    STAssertTrue(testViewControllerDidUnloadCalled, @"");
}

- (void)testViewAppearance {
    TestViewController *vc = [[TestViewController alloc] init];
    [self.visibleView addSubview:vc.view];

    STAssertTrue(vc.viewWillAppearCalled, @"");
    STAssertTrue(vc.viewDidAppearCalled, @"");
}

- (void)testViewDisappearance {
    TestViewController *vc = [[TestViewController alloc] init];
    [self.visibleView addSubview:vc.view];

    [vc.view removeFromSuperview];
    STAssertTrue(vc.viewWillDisappearCalled, @"");
    STAssertTrue(vc.viewDidDisappearCalled, @"");
}

- (void)testMovingBetweenSuperviews {
    TestViewController *vc = [[TestViewController alloc] init];

    VELView *firstSuperview = [[VELView alloc] init];
    [self.visibleView addSubview:firstSuperview];

    VELView *secondSuperview = [[VELView alloc] init];
    [self.visibleView addSubview:secondSuperview];

    [firstSuperview addSubview:vc.view];

    // clear out the flags before we change its superview
    vc.viewWillAppearCalled = NO;
    vc.viewDidAppearCalled = NO;

    [secondSuperview addSubview:vc.view];

    // moving superviews should not generate new lifecycle messages
    STAssertFalse(vc.viewWillAppearCalled, @"");
    STAssertFalse(vc.viewDidAppearCalled, @"");
    STAssertFalse(vc.viewWillDisappearCalled, @"");
    STAssertFalse(vc.viewDidDisappearCalled, @"");
}

- (void)testResponderChainWithoutSuperviewOrHostView {
    VELViewController *vc = [[VELViewController alloc] init];

    // a view's next responder should be its view controller
    STAssertEquals(vc.view.nextResponder, vc, @"");

    // the view controller's next responder should be nil in this case
    STAssertNil(vc.nextResponder, @"");
}

- (void)testResponderChainWithSuperview {
    VELViewController *vc = [[VELViewController alloc] init];

    VELView *superview = [[VELView alloc] init];
    [superview addSubview:vc.view];

    // verify that our view's next responder is still correct
    STAssertEquals(vc.view.nextResponder, vc, @"");

    // the view controller's next responder should be the superview
    STAssertEquals(vc.nextResponder, superview, @"");
}

- (void)testResponderChainWithHostView {
    VELViewController *vc = [[VELViewController alloc] init];

    NSVelvetView *hostView = self.window.contentView;
    hostView.guestView = vc.view;

    // verify that our view's next responder is still correct
    STAssertEquals(vc.view.nextResponder, vc, @"");

    // the view controller's next responder should be the host view
    STAssertEquals(vc.nextResponder, hostView, @"");
}

- (void)testResponderChainWithSuperviewAndHostView {
    VELViewController *vc = [[VELViewController alloc] init];

    [self.visibleView addSubview:vc.view];

    // the view controller's next responder should be the superview, not the
    // host view
    STAssertEquals(vc.nextResponder, self.visibleView, @"");
}

- (void)testRemovesUndoActionsOnDealloc {
    // need a responder class that creates an undo manager
    NSDocument *document = [[NSDocument alloc] init];
    document.hasUndoManager = YES;

    NSUndoManager *undoManager = document.undoManager;
    STAssertNotNil(undoManager, @"");

    undoManager.groupsByEvent = NO;
    STAssertFalse(undoManager.canUndo, @"");

    @autoreleasepool {
        __autoreleasing VELViewController *viewController = [[VELViewController alloc] init];
        
        // NSDocument is not actually an NSResponder, but it behaves like one
        viewController.nextResponder = (id)document;

        // add an undo action to the stack
        [undoManager beginUndoGrouping];
        [[undoManager prepareWithInvocationTarget:viewController] viewWillAppear];
        [undoManager endUndoGrouping];

        STAssertTrue(undoManager.canUndo, @"");
    }

    // the undo stack should be empty after the view is deallocated
    STAssertFalse(undoManager.canUndo, @"");
}

@end

@implementation TestViewController
@synthesize viewWillAppearCalled;
@synthesize viewDidAppearCalled;
@synthesize viewWillDisappearCalled;
@synthesize viewDidDisappearCalled;

- (VELView *)loadView {
    VELView *view = [super loadView];

    NSAssert(!self.viewWillAppearCalled, @"");
    NSAssert(!self.viewDidAppearCalled, @"");
    NSAssert(!self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    return view;
}

- (void)viewWillAppear {
    [super viewWillAppear];

    NSAssert(self.viewLoaded, @"");
    NSAssert(!self.viewWillAppearCalled, @"");
    NSAssert(!self.viewDidAppearCalled, @"");
    NSAssert(!self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(!self.view.superview, @"");
    NSAssert(!self.view.window, @"");

    self.viewWillAppearCalled = YES;
}

- (void)viewDidAppear {
    [super viewDidAppear];

    NSAssert(self.viewLoaded, @"");
    NSAssert(self.viewWillAppearCalled, @"");
    NSAssert(!self.viewDidAppearCalled, @"");
    NSAssert(!self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(self.view.superview, @"");
    NSAssert(self.view.window, @"");

    self.viewDidAppearCalled = YES;
}

- (void)viewWillDisappear {
    [super viewWillDisappear];

    NSAssert(self.viewLoaded, @"");
    NSAssert(self.viewWillAppearCalled, @"");
    NSAssert(self.viewDidAppearCalled, @"");
    NSAssert(!self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(self.view.superview, @"");
    NSAssert(self.view.window, @"");

    self.viewWillDisappearCalled = YES;
}

- (void)viewDidDisappear {
    [super viewDidDisappear];

    NSAssert(self.viewLoaded, @"");
    NSAssert(self.viewWillAppearCalled, @"");
    NSAssert(self.viewDidAppearCalled, @"");
    NSAssert(self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(!self.view.superview, @"");
    NSAssert(!self.view.window, @"");

    self.viewDidDisappearCalled = YES;
}

- (void)viewWillUnload {
    [super viewWillUnload];

    NSAssert(self.viewLoaded, @"");
    NSAssert(!testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    NSAssert(!self.view.superview, @"");
    NSAssert(!self.view.window, @"");

    testViewControllerWillUnloadCalled = YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];

    NSAssert(!self.viewLoaded, @"");
    NSAssert(testViewControllerWillUnloadCalled, @"");
    NSAssert(!testViewControllerDidUnloadCalled, @"");

    testViewControllerDidUnloadCalled = YES;
}

@end
