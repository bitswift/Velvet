//
//  VELViewControllerTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 21.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>

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
- (void)notificationFired:(NSNotification *)notification;
@end

SpecBegin(VELViewController)

    __block VELWindow *window;
    
    before(^{
        testViewControllerWillUnloadCalled = NO;
        testViewControllerDidUnloadCalled = NO;

        window = [[VELWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 500)];
        expect(window).not.toBeNil();
    });

    it(@"should remove undo manager actions when deallocating", ^{
        // need a responder class that creates an undo manager
        NSDocument *document = [[NSDocument alloc] init];
        document.hasUndoManager = YES;

        NSUndoManager *undoManager = document.undoManager;
        expect(undoManager).not.toBeNil();

        undoManager.groupsByEvent = NO;
        expect(undoManager.canUndo).toBeFalsy();

        @autoreleasepool {
            __attribute__((objc_precise_lifetime)) VELViewController *viewController = [[VELViewController alloc] init];
            
            // NSDocument is not actually an NSResponder, but it behaves like one
            viewController.nextResponder = (id)document;

            // add an undo action to the stack
            [undoManager beginUndoGrouping];
            [[undoManager prepareWithInvocationTarget:viewController] viewWillAppear];
            [undoManager endUndoGrouping];

            expect(undoManager.canUndo).toBeTruthy();
        }

        // the undo stack should be empty after the view is deallocated
        expect(undoManager.canUndo).toBeFalsy();
    });

    it(@"should remove itself as an observer to any notifications", ^{
        __weak __block TestViewController *testVC;
        
        @autoreleasepool {
            __attribute__((objc_precise_lifetime)) TestViewController *viewController = [[TestViewController alloc] init];
            testVC = viewController;
            
            [[NSNotificationCenter defaultCenter] addObserver:viewController selector:@selector(notificationFired:) name:@"Test Notification" object:nil];

            expect([^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Test Notification" object:nil];
            } copy]).toInvoke(viewController, @selector(notificationFired:));
        }  

        [[NSNotificationCenter defaultCenter] postNotificationName:@"Test Notification" object:nil];    
    });

    describe(@"VELViewController", ^{
        __block VELViewController *controller;

        before(^{
            controller = [[VELViewController alloc] init];
            expect(controller).not.toBeNil();

            expect(controller.viewLoaded).toBeFalsy();
        });

        it(@"should implicitly load its view when the property is accessed", ^{
            VELView *view = controller.view;
            expect(view).not.toBeNil();
            expect(controller.viewLoaded).toBeTruthy();

            // re-reading the property should return the same view
            expect(controller.view).toEqual(view);
        });

        it(@"should load an empty, zero-sized view", ^{
            VELView *view = [controller loadView];
            expect(view).not.toBeNil();

            expect(CGRectIsEmpty(view.frame)).toBeTruthy();
        });

        describe(@"focused state", ^{
            before(^{
                [window.rootView addSubview:controller.view];
            
                expect(controller.focused).toBeFalsy();
                expect(controller.view.focused).toBeFalsy();
            });

            describe(@"with one view controller", ^{
                after(^{
                    expect(controller.view.focused).toBeTruthy();
                    expect(controller.focused).toBeTruthy();
                });
                
                it(@"should become focused when its view becomes first responder", ^{
                    [window makeFirstResponder:controller.view];
                });
                
                it(@"should become focused when its subview becomes first responder", ^{
                    VELView *subview = [[VELView alloc] init];
                    
                    [controller.view addSubview:subview];
                    
                    expect(subview.focused).toBeFalsy();
                    
                    [window makeFirstResponder:subview];
                    
                    expect(subview.focused).toBeTruthy();
                });
                
                it(@"should become focused when a descendant view becomes first responder", ^{
                    VELView *subview = [[VELView alloc] init];
                    VELView *descendantView = [[VELView alloc] init];
                    
                    [subview addSubview:descendantView];
                    [controller.view addSubview:subview];
                    
                    expect(descendantView.focused).toBeFalsy();
                    
                    [window makeFirstResponder:descendantView];
                    
                    expect(descendantView.focused).toBeTruthy();
                });
                
                it(@"should unfocus if the window becomes first responder", ^{
                    [window makeFirstResponder:controller.view];
                    [window makeFirstResponder:nil]; 

                    expect(controller.focused).toBeFalsy();
                    
                    [window makeFirstResponder:controller.view];
                });
            });

            describe(@"with sub view controllers", ^{
                __block VELViewController *subviewController;
                __block VELView *subview;

                before(^{
                    subviewController = [[VELViewController alloc] init];
                    subview = [[VELView alloc] init];

                    [subviewController.view addSubview:subview];
                    [controller.view addSubview:subviewController.view];

                    expect(subviewController.focused).toBeFalsy();
                    expect(subviewController.view.focused).toBeFalsy();
                    expect(subview.focused).toBeFalsy();
                });

                after(^{
                    expect(controller.focused).toBeFalsy();
                    expect(controller.view.focused).toBeFalsy();
                    expect(subviewController.focused).toBeTruthy();
                    expect(subviewController.view.focused).toBeTruthy();
                    expect(subview.focused).toBeTruthy();
                });

                it(@"should not be focused when a descendant view controller's view becomes first responder", ^{
                    [window makeFirstResponder:subview];
                });

                it(@"should lose focus when it is focused and a descendant view controller's view becomes first responder", ^{
                    [window makeFirstResponder:controller.view];

                    expect(controller.focused).toBeTruthy();
                    expect(controller.view.focused).toBeTruthy();

                    [window makeFirstResponder:subview];
                });
            });
        });

        describe(@"responder chain", ^{
            before(^{
                expect(controller.view.nextResponder).toEqual(controller);
            });

            after(^{
                // no matter what happened, the view's next responder should
                // still be its controller
                expect(controller.view.nextResponder).toEqual(controller);
            });

            it(@"should have no next responder by default", ^{
                expect(controller.nextResponder).toBeNil();
            });

            it(@"should have its view's superview as a next responder", ^{
                VELView *superview = [[VELView alloc] init];
                [superview addSubview:controller.view];

                expect(controller.nextResponder).toEqual(superview);
            });

            it(@"should have its view's immediate hostView as a next responder", ^{
                window.rootView = controller.view;

                expect(controller.nextResponder).toEqual(window.contentView);
            });

            it(@"should have its view's superview as a next responder before any hostView", ^{
                [window.rootView addSubview:controller.view];

                expect(controller.nextResponder).toEqual(window.rootView);
            });
        });

        describe(@"parent view controller", ^{
            it(@"should not have a parent view controller by default", ^{
                expect(controller.parentViewController).toBeNil();
            });

            it(@"should be the parent view controller of a direct subview", ^{
                VELViewController *subviewController = [[VELViewController alloc] init];
                [controller.view addSubview:subviewController.view];

                expect(subviewController.parentViewController).toEqual(controller);
            });

            it(@"should be the parent view controller of a descendant", ^{
                VELView *subview = [[VELView alloc] init];
                [controller.view addSubview:subview];

                VELViewController *descendantViewController = [[VELViewController alloc] init];
                [subview addSubview:descendantViewController.view];

                expect(descendantViewController.parentViewController).toEqual(controller);
            });

            it(@"should find a parent view controller across hierarchies", ^{
                NSVelvetView *velvetHostView = [[NSVelvetView alloc] initWithFrame:CGRectZero];
                VELNSView *appKitHostView = [[VELNSView alloc] initWithNSView:velvetHostView];

                [controller.view addSubview:appKitHostView];

                VELViewController *subviewController = [[VELViewController alloc] init];
                [velvetHostView.guestView addSubview:subviewController.view];

                expect(subviewController.parentViewController).toEqual(controller);
            });

        });
    });

    it(@"should unload its view when deallocated", ^{
        @autoreleasepool {
            __attribute__((objc_precise_lifetime)) TestViewController *controller = [[TestViewController alloc] init];

            // access the view property to load it in
            [controller view];
        }
        
        expect(testViewControllerWillUnloadCalled).toBeTruthy();
        expect(testViewControllerDidUnloadCalled).toBeTruthy();
    });

    describe(@"custom subclass", ^{
        __block TestViewController *controller;

        before(^{
            controller = [[TestViewController alloc] init];
        });

        it(@"should invoke viewWillAppear and viewDidAppear", ^{
            [window.rootView addSubview:controller.view];

            expect(controller.viewWillAppearCalled).toBeTruthy();
            expect(controller.viewDidAppearCalled).toBeTruthy();
        });

        it(@"should invoke viewWillDisappear and viewDidDisappear", ^{
            [window.rootView addSubview:controller.view];
            [controller.view removeFromSuperview];

            expect(controller.viewWillDisappearCalled).toBeTruthy();
            expect(controller.viewDidDisappearCalled).toBeTruthy();
        });

        it(@"should invoke view lifecycle methods when switching view superviews", ^{
            VELView *firstSuperview = [[VELView alloc] init];
            [window.rootView addSubview:firstSuperview];

            VELView *secondSuperview = [[VELView alloc] init];
            [window.rootView addSubview:secondSuperview];

            [firstSuperview addSubview:controller.view];

            // clear out the flags before we change its superview
            controller.viewWillAppearCalled = NO;
            controller.viewDidAppearCalled = NO;

            [secondSuperview addSubview:controller.view];

            // moving superviews should not generate new lifecycle messages
            expect(controller.viewWillAppearCalled).toBeFalsy();
            expect(controller.viewDidAppearCalled).toBeFalsy();
            expect(controller.viewWillDisappearCalled).toBeFalsy();
            expect(controller.viewDidDisappearCalled).toBeFalsy();
        });
    });

SpecEnd

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

    return view;
}

- (void)viewWillAppear {
    [super viewWillAppear];

    NSAssert(self.viewLoaded, @"");
    NSAssert(!self.viewWillAppearCalled, @"");
    NSAssert(!self.viewDidAppearCalled, @"");
    NSAssert(!self.viewWillDisappearCalled, @"");
    NSAssert(!self.viewDidDisappearCalled, @"");

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

    NSAssert(!self.view.superview, @"");
    NSAssert(!self.view.window, @"");

    self.viewDidDisappearCalled = YES;
}

- (void)viewWillUnload {
    [super viewWillUnload];

    NSAssert(self.viewLoaded, @"");
    NSAssert(!self.view.superview, @"");
    NSAssert(!self.view.window, @"");

    testViewControllerWillUnloadCalled = YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];

    NSAssert(!self.viewLoaded, @"");

    testViewControllerDidUnloadCalled = YES;
}

- (void)notificationFired:(NSNotification *)notification {

}

@end
