//
//  VELViewTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 08.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@interface TestView : VELView
@property (nonatomic, assign) BOOL willMoveToSuperviewInvoked;
@property (nonatomic, assign) BOOL willMoveToWindowInvoked;
@property (nonatomic, assign) BOOL didMoveFromSuperviewInvoked;
@property (nonatomic, assign) BOOL didMoveFromWindowInvoked;
@property (nonatomic, assign) BOOL viewHierarchyDidChangeInvoked;
@property (nonatomic, unsafe_unretained) VELView *oldSuperview;
@property (nonatomic, unsafe_unretained) VELView *nextSuperview;
@property (nonatomic, unsafe_unretained) VELWindow *oldWindow;
@property (nonatomic, unsafe_unretained) VELWindow *nextWindow;
@property (nonatomic, assign) CGRect drawRectRegion;
@property (nonatomic, assign) BOOL layoutSubviewsInvoked;

- (void)reset;
@end

@interface TestEditorDelegate : NSObject
- (void)editor:(id)editor didCommit:(BOOL)didCommit contextInfo:(void *)contextInfo;
@end

// Tests BS-1324
@interface FrameSettingView : VELView
@property (nonatomic, strong, readonly) VELView *subview;
@end

// Tests BS-1891
@interface OddFittingSizeView : VELView
@end

SpecBegin(VELView)

describe(@"VELView", ^{
    __block VELWindow *window;
    __block VELView *view;

    before(^{
        window = [[VELWindow alloc]
            initWithContentRect:CGRectMake(100, 100, 500, 500)
            styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
            backing:NSBackingStoreBuffered
            defer:NO
            screen:nil
        ];

        view = [[VELView alloc] init];
    });

    after(^{
        // tear down the view before the window containing it
        view = nil;
        window = nil;
    });

    it(@"initializes", ^{
        expect(view.alignsToIntegralPixels).toBeTruthy();
        expect(view.clearsContextBeforeDrawing).toBeTruthy();
        expect(view.contentMode).toEqual(VELViewContentModeScaleToFill);
        expect(view.hidden).toBeFalsy();
        expect(view.hostView).toBeNil();
        expect(view.layer).not.toBeNil();
        expect(view.opaque).toBeFalsy();
        expect(view.superview).toBeNil();
        expect(view.userInteractionEnabled).toBeTruthy();
    });

    it(@"sizes itself around its center when calling centeredSizeToFit", ^{
        VELView *subview = [[VELView alloc] initWithFrame:CGRectMake(100, 0, 300, 200)];

        [view addSubview:subview];
        [view centeredSizeToFit];

        expect(view.bounds.size.width).toEqual(400);
        expect(view.bounds.size.height).toEqual(200);
    });

    it(@"removes itself from its superview", ^{
        VELView *subview = [[VELView alloc] init];

        [view addSubview:subview];

        expect([subview superview]).toEqual(view);
        expect([[view subviews] lastObject]).toEqual(subview);

        [subview removeFromSuperview];
        expect([subview superview]).toBeNil();
        expect([[view subviews] count]).toEqual(0);
    });

    it(@"sets subviews", ^{
        NSMutableArray *subviews = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0;i < 4;++i) {
            [subviews addObject:[[VELView alloc] init]];
        }

        // make sure that -setSubviews: does not throw an exception
        // (such as mutation while enumerating)
        view.subviews = subviews;

        // the two arrays should have the same objects, but should not be the same
        // array instance
        expect(view.subviews == subviews).toBeFalsy();
        expect(view.subviews).toEqual(subviews);

        // removing the last subview should remove the last object from the subviews
        // array
        [[subviews lastObject] removeFromSuperview];
        [subviews removeLastObject];

        expect(view.subviews).toEqual(subviews);

        NSMutableArray *expectedSublayers = [view.layer.sublayers mutableCopy];
        [subviews exchangeObjectAtIndex:0 withObjectAtIndex:2];
        [expectedSublayers exchangeObjectAtIndex:0 withObjectAtIndex:2];

        // calling -setSubviews: with a new array should replace the old one
        view.subviews = subviews;
        expect(view.subviews).toEqual(subviews);
        expect(view.layer.sublayers).toEqual(expectedSublayers);
    });

    describe(@"responder chain", ^{
        it(@"has a nil responder chain by default", ^{
            expect(view.nextResponder).toBeNil();
        });

        it(@"has a nextResponder when it is a subview", ^{
            VELView *superview = [[VELView alloc] init];
            [superview addSubview:view];

            // the view's next responder should be the superview
            expect(view.nextResponder).toEqual(superview);
        });

        it(@"has a nextResponder when it has a hostView", ^{
            NSVelvetView *hostView = window.contentView;
            hostView.guestView = view;

            // the view's next responder should be the host view
            expect(view.nextResponder).toEqual(hostView);
        });
        
        it(@"descends from its hostView when it has a view", ^{
            NSVelvetView *hostView = window.contentView;
            hostView.guestView = view;
            expect([view isDescendantOfView:hostView]).toBeTruthy();
        });

        it(@"has a next responder with a superview and hostView", ^{
            [window.rootView addSubview:view];

            // the view's next responder should be the superview, not the host view
            expect(view.nextResponder).toEqual(window.rootView);

        });

        it(@"changes nextResponder when moving between hostViews", ^{
            NSVelvetView *firstHostView = [[NSVelvetView alloc] initWithFrame:CGRectZero];
            NSVelvetView *secondHostView = [[NSVelvetView alloc] initWithFrame:CGRectZero];

            firstHostView.guestView = view;
            expect(view.nextResponder).toEqual(firstHostView);

            secondHostView.guestView = view;
            expect(view.nextResponder).toEqual(secondHostView);
        });

        it(@"has a nextResponder with a hostView that is not an NSVelvetView", ^{
            id<VELHostView> hostView = [[VELNSView alloc] init];

            // obviously a VELNSView should never host a VELView, but this use case
            // mirrors that of our TwUI bridge, and previously a exposed a flaw in how
            // responder chain updates were triggered
            view.hostView = hostView;
            expect(view.nextResponder).toEqual(hostView);
        });
    });

    it(@"should return a rendered CGImage", ^{
        view.frame = CGRectMake(0, 0, 40, 40);

        CGImageRef image = view.renderedCGImage;
        expect(image).not.toBeNil();
    });

    it(@"implements pointInside:", ^{
        view.frame = CGRectMake(0, 0, 50, 50);

        expect([view pointInside:CGPointMake(25, 25)]).toBeTruthy();
        expect([view pointInside:CGPointMake(-1, -1)]).toBeFalsy();
        expect([view pointInside:CGPointMake(50, 50)]).toBeFalsy();
        expect([view pointInside:CGPointMake(49, 49)]).toBeTruthy();
    });

    it(@"has a fully flexible autoresizingMask", ^{
        VELView *superview = [[VELView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

        view.frame = CGRectMake(20, 20, 60, 60);
        [superview addSubview:view];

        view.autoresizingMask = VELViewAutoresizingFlexibleLeftMargin | VELViewAutoresizingFlexibleRightMargin | VELViewAutoresizingFlexibleTopMargin | VELViewAutoresizingFlexibleBottomMargin;

        superview.frame = CGRectMake(0, 0, 1000, 1000);

        // force a layout
        [superview.layer setNeedsLayout];
        [superview.layer layoutIfNeeded];

        CGRect expectedFrame = CGRectMake(470, 470, 60, 60);
        expect(view.frame).toEqual(expectedFrame);
    });

    it(@"aligns to integral points when settings its frame", ^{
        view.frame = CGRectMake(10.25, 11.5, 12.75, 13.01);

        CGRect expectedFrame = CGRectMake(10, 12, 12, 13);
        expect(view.frame).toEqual(expectedFrame);
    });

    it(@"aligns to integral points when settings its bounds", ^{
        view.bounds = CGRectMake(0, 0, 12.75, 13.01);

        CGRect expectedBounds = CGRectMake(0, 0, 12, 13);
        expect(view.bounds).toEqual(expectedBounds);
    });

    it(@"aligns to integral points when setting a misaligned center", ^{
        view.frame = CGRectMake(0, 0, 50, 50);
        view.center = CGPointMake(13.7, 14.3);

        CGPoint expectedCenter = CGPointMake(13, 15);
        expect(CGPointEqualToPoint(view.center, expectedCenter)).toBeTruthy();
    });

    it(@"respects a misaligned center when its size is CGSizeZero", ^{
        CGPoint expectedCenter = CGPointMake(13.7, 14.3);
        view.center = expectedCenter;
        expect(CGPointEqualToPoint(view.center, expectedCenter)).toBeTruthy();
    });

    it(@"aligns to integral points when setting a center resulting in a misaligned frame", ^{
        VELView *view = [[VELView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];

        view.center = CGPointMake(15, 15);

        CGRect expectedFrame = CGRectMake(12, 13, 5, 5);
        expect(view.frame).toEqual(expectedFrame);
    });

    it(@"aligns to integral points when autoresizing", ^{
        VELView *superview = [[VELView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];

        VELView *subview = [[VELView alloc] initWithFrame:CGRectMake(5, 5, 20, 20)];
        subview.autoresizingMask = VELViewAutoresizingFlexibleMargins;
        [superview addSubview:subview];

        superview.frame = CGRectMake(0, 0, 25, 25);

        CGRect expectedSubviewFrame = CGRectMake(2, 3, 20, 20);
        expect(subview.frame).toEqual(expectedSubviewFrame);
    });

    it(@"aligns to integral points when sizing to fit, even starting on half-pixels", ^{
        OddFittingSizeView *oddView = [[OddFittingSizeView alloc] initWithFrame:CGRectZero];
        [window.rootView addSubview:oddView];

        oddView.layer.bounds = CGRectMake(-0.5, 0, 2, 2);

        CGPoint oldCenter = oddView.center;
        [oddView centeredSizeToFit];

        CGRect expectedRect = CGRectFloor(CGRectMake(
            oldCenter.x - oddView.bounds.size.width / 2,
            oldCenter.y - oddView.bounds.size.height / 2,
            oddView.bounds.size.width,
            oddView.bounds.size.height
        ));
        
        NSLog(@"oddView.frame: %@", NSStringFromRect(oddView.frame));
        NSLog(@"expectedRect: %@", NSStringFromRect(expectedRect));

        expect(oddView.frame).toEqual(expectedRect);
    });

    it(@"conforms to VELBridgedView", ^{
        expect([VELView class]).toConformTo(@protocol(VELBridgedView));
        expect(view).toConformTo(@protocol(VELBridgedView));
    });

    describe(@"geometry conversion", ^{
        CGRect windowRect = CGRectMake(175, 355, 100, 100);
        CGRect viewRect = CGRectMake(125, 255, 100, 100);
        CGRect subviewRect = CGRectMake(115, 245, 50, 50);
        __block VELView *subview = [[VELView alloc] init];

        before(^{
            view.frame = CGRectMake(50, 100, 100, 200);
            subview.frame = CGRectMake(10, 10, 50, 50);
            [window.rootView addSubview:view];
            [view addSubview:subview];
        });

        it(@"can convert from a window point to its own coordinate space", ^{
            expect([view convertFromWindowPoint:windowRect.origin]).toEqual(viewRect.origin);
            expect([view convertPoint:windowRect.origin fromView:nil]).toEqual(viewRect.origin);
        });

        it(@"can convert to a window point from its own coordinate space", ^{
            expect([view convertToWindowPoint:viewRect.origin]).toEqual(windowRect.origin);
            expect([view convertPoint:viewRect.origin toView:nil]).toEqual(windowRect.origin);
        });

        it(@"can convert from a window rect", ^{
            expect([view convertFromWindowRect:windowRect]).toEqual(viewRect);
            expect([view convertRect:windowRect fromView:nil]).toEqual(viewRect);
        });

        it(@"can convert to a window rect", ^{
            expect([view convertToWindowRect:viewRect]).toEqual(windowRect);
            expect([view convertRect:viewRect toView:nil]).toEqual(windowRect);
        });

        it(@"can convert a point to another view's coordinate space", ^{
            expect([view convertPoint:viewRect.origin toView:subview]).toEqual(subviewRect.origin);
        });
        
        it(@"can convert a point into its own coordinate space", ^{
            expect([view convertPoint:subviewRect.origin fromView:subview]).toEqual(viewRect.origin);
        });

        it(@"can convert a rect to another view's coordinate space", ^{
            expect([view convertRect:subview.frame toView:subview]).toEqual(subview.bounds);
        });

        it(@"can convert a rect from another view's coordinate space", ^{
            expect([view convertRect:subview.bounds fromView:subview]).toEqual(subview.frame);
        });
    });

    describe(@"scrolling to include a rectangle", ^{
        __block NSScrollView *scrollView;

        before(^{
            scrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

            VELNSView *hostView = [[VELNSView alloc] initWithNSView:scrollView];
            [window.rootView addSubview:hostView];
        });

        before(^{
            NSVelvetView *hostView = [[NSVelvetView alloc] init];
            [hostView.guestView addSubview:view];

            scrollView.documentView = hostView;
        });

        it(@"should scroll an ancestor NSScrollView to a rectangle in the same coordinate system", ^{
            view.frame = CGRectMake(0, 0, 1000, 1000);

            [view scrollToIncludeRect:CGRectMake(250, 350, 75, 50)];
            expect(scrollView.contentView.documentVisibleRect).isGoing.toEqual(CGRectMake(225, 300, 100, 100));
        });

        it(@"should scroll an ancestor NSScrollView to a rectangle in a different coordinate system", ^{
            view.frame = CGRectMake(100, 200, 1000, 1000);

            [view scrollToIncludeRect:CGRectMake(250, 350, 75, 50)];
            expect(scrollView.contentView.documentVisibleRect).isGoing.toEqual(CGRectMake(325, 500, 100, 100));
        });
    });

    it(@"has a layer", ^{
        expect(view.layer).not.toBeNil();
    });

    it(@"has a hostView", ^{
        expect(view.hostView).toBeNil();
        window.rootView = view;
        expect(view.hostView).toEqual(window.contentView);
    });

    it(@"returns its hostView as the immediateParentView when it has one", ^{
        window.rootView = view;
        expect(view.immediateParentView).toEqual(window.contentView);
    });

    it(@"returns its superview as the immediateParentView when the hostView is not immediate", ^{
        [window.rootView addSubview:view];
        expect(view.immediateParentView).toEqual(window.rootView);
    });

    it(@"does not throw an exception when calling -ancestorDidLayout", ^{
        [view ancestorDidLayout];
    });

    it(@"has an ancestorNSVelvetView when adding it as a subview to an NSVelvetView subview", ^{
        [window.rootView addSubview:view];
        expect(view.ancestorNSVelvetView).toEqual(window.contentView);
    });

    it(@"has an ancestorScrollView when it is a subview of an NSScrollView's documentView", ^{
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];

        NSVelvetView *velvetView = [[NSVelvetView alloc] initWithFrame:CGRectZero];
        [scrollView setDocumentView:velvetView];

        expect(velvetView.guestView.ancestorScrollView).toEqual(scrollView.contentView);
    });

    it(@"does not throw an exception when calling -willMoveToNSVelvetView:", ^{
        [view willMoveToNSVelvetView:nil];
    });

    it(@"does not throw an exception when calling -didMoveFromNSVelvetView", ^{
        [view didMoveFromNSVelvetView:nil];
    });

    describe(@"implements descendantViewAtPoint:", ^{
        __block VELView *superview;
        __block VELView *subview;

        CGPoint superviewPoint = CGPointMake(49, 29);
        CGPoint subviewPoint = CGPointMake(51, 31);
        CGPoint outsidePoint = CGPointMake(49, 200);

        before(^{
            superview = [[VELView alloc] initWithFrame:CGRectMake(20, 20, 80, 80)];
            [window.rootView addSubview:superview];

            subview = [[VELView alloc] initWithFrame:CGRectMake(50, 30, 100, 150)];
            [superview addSubview:subview];
        });

        it(@"returns a subview when given a subview point", ^{
            expect([superview descendantViewAtPoint:subviewPoint]).toEqual(subview);
        });

        it(@"returns a superview when given a superview point", ^{
            expect([superview descendantViewAtPoint:superviewPoint]).toEqual(superview);
        });

        it(@"returns nil when given an outside point", ^{
            expect([superview descendantViewAtPoint:outsidePoint]).toBeNil();
        });

        it(@"should not return self with user interaction disabled", ^{
            superview.userInteractionEnabled = NO;
            expect([superview descendantViewAtPoint:superviewPoint]).toBeNil();
        });

        it(@"should not return a subview with superview user interaction disabled", ^{
            superview.userInteractionEnabled = NO;
            expect([superview descendantViewAtPoint:subviewPoint]).toBeNil();
        });

        it(@"should not return a subview that has user interaction disabled", ^{
            subview.userInteractionEnabled = NO;
            expect([superview descendantViewAtPoint:subviewPoint]).toEqual(superview);
        });

        it(@"should not return self when hidden", ^{
            superview.hidden = YES;
            expect([superview descendantViewAtPoint:superviewPoint]).toBeNil();
        });

        it(@"should not return a subview with superview hidden", ^{
            superview.hidden = YES;
            expect([superview descendantViewAtPoint:subviewPoint]).toBeNil();
        });

        it(@"should not return a hidden subview", ^{
            subview.hidden = YES;
            expect([superview descendantViewAtPoint:subviewPoint]).toEqual(superview);
        });
    });

    it(@"removes undo actions on dealloc", ^{
        // need a responder class that creates an undo manager
        NSDocument *document = [[NSDocument alloc] init];
        document.hasUndoManager = YES;

        NSUndoManager *undoManager = document.undoManager;
        expect(undoManager).not.toBeNil();

        undoManager.groupsByEvent = NO;
        expect(undoManager.canUndo).toBeFalsy();

        @autoreleasepool {
            __autoreleasing VELView *view = [[VELView alloc] init];

            // NSDocument is not actually an NSResponder, but it behaves like one
            view.nextResponder = (id)document;

            // add an undo action to the stack
            [undoManager beginUndoGrouping];
            [[undoManager prepareWithInvocationTarget:view]
                setFrame:CGRectMake(0, 0, 100, 100)
            ];

            [undoManager endUndoGrouping];

            STAssertTrue(undoManager.canUndo, @"");
            expect(undoManager.canUndo).toBeTruthy();
        }

        // the undo stack should be empty after the view is deallocated
        expect(undoManager.canUndo).toBeFalsy();
    });

    describe(@"subclass", ^{
        __block TestView *testView;

        before(^{
            testView = [[TestView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            expect(testView).not.toBeNil();
        });

        it(@"should invoke callback methods when moving to first superview", ^{
            testView.nextSuperview = view;
            [view addSubview:testView];

            expect(testView.willMoveToSuperviewInvoked).toBeTruthy();
            expect(testView.didMoveFromSuperviewInvoked).toBeTruthy();
            expect(testView.willMoveToWindowInvoked).toBeFalsy();
            expect(testView.didMoveFromWindowInvoked).toBeFalsy();
            expect(testView.viewHierarchyDidChangeInvoked).toBeTruthy();
        });

        it(@"should not invoke callback methods when superview changes superviews", ^{
            VELView *superview = [[VELView alloc] init];
            testView.nextSuperview = superview;
            [superview addSubview:testView];

            [testView reset];
            [view addSubview:superview];

            expect(testView.willMoveToSuperviewInvoked).toBeFalsy();
            expect(testView.didMoveFromSuperviewInvoked).toBeFalsy();
            expect(testView.willMoveToWindowInvoked).toBeFalsy();
            expect(testView.didMoveFromWindowInvoked).toBeFalsy();
            expect(testView.viewHierarchyDidChangeInvoked).toBeTruthy();
        });

        it(@"should invoke callback methods when changing superviews", ^{
            testView.nextSuperview = view;
            [view addSubview:testView];

            VELView *secondSuperview = [[VELView alloc] init];

            // reset everything for the crossing over test
            [testView reset];

            testView.oldSuperview = view;
            testView.nextSuperview = secondSuperview;

            [secondSuperview addSubview:testView];

            expect(testView.willMoveToSuperviewInvoked).toBeTruthy();
            expect(testView.didMoveFromSuperviewInvoked).toBeTruthy();
            expect(testView.willMoveToWindowInvoked).toBeFalsy();
            expect(testView.didMoveFromWindowInvoked).toBeFalsy();
            expect(testView.viewHierarchyDidChangeInvoked).toBeTruthy();
        });

        it(@"should invoke callback methods when changing windows", ^{
            VELWindow *firstWindow = window;
            VELWindow *secondWindow = [[VELWindow alloc]
                initWithContentRect:CGRectMake(100, 100, 500, 500)
                styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
                backing:NSBackingStoreBuffered
                defer:NO
                screen:nil
            ];

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
            expect(testView.willMoveToWindowInvoked).toBeTruthy();
            expect(testView.didMoveFromWindowInvoked).toBeTruthy();
            expect(testView.willMoveToWindowInvoked).toBeTruthy();
            expect(testView.didMoveFromWindowInvoked).toBeTruthy();
            expect(testView.viewHierarchyDidChangeInvoked).toBeTruthy();
        });

        it(@"should invoke callback methods when moving to first window via superview", ^{
            testView.nextSuperview = window.rootView;
            testView.nextWindow = window;

            [window.rootView addSubview:testView];

            expect(testView.willMoveToSuperviewInvoked).toBeTruthy();
            expect(testView.didMoveFromSuperviewInvoked).toBeTruthy();
            expect(testView.willMoveToWindowInvoked).toBeTruthy();
            expect(testView.didMoveFromWindowInvoked).toBeTruthy();
            expect(testView.viewHierarchyDidChangeInvoked).toBeTruthy();
        });

        it(@"should invoke callback methods when becoming a window's root view", ^{
            testView.nextWindow = window;
            window.contentView.guestView = testView;

            expect(testView.willMoveToSuperviewInvoked).toBeFalsy();
            expect(testView.didMoveFromSuperviewInvoked).toBeFalsy();
            expect(testView.willMoveToWindowInvoked).toBeTruthy();
            expect(testView.didMoveFromWindowInvoked).toBeTruthy();
            expect(testView.viewHierarchyDidChangeInvoked).toBeTruthy();
        });

        it(@"should notify about view hierarchy changes when reordered in superview", ^{
            testView.nextSuperview = view;

            [view addSubview:[[VELView alloc] init]];
            [view addSubview:testView];

            [testView reset];

            view.subviews = view.subviews.reverseObjectEnumerator.allObjects;
            expect(testView.viewHierarchyDidChangeInvoked).toBeTruthy();
        });

        it(@"should notify about view hierarchy changes when reordered in ancestor", ^{
            VELView *superview = [[VELView alloc] init];
            testView.nextSuperview = superview;
            [superview addSubview:testView];

            [view addSubview:[[VELView alloc] init]];
            [view addSubview:superview];

            [testView reset];

            view.subviews = view.subviews.reverseObjectEnumerator.allObjects;
            expect(testView.viewHierarchyDidChangeInvoked).toBeTruthy();
        });

        it(@"only draws a dirty rect", ^{
            [testView.layer displayIfNeeded];

            CGRect invalidatedRegion = CGRectMake(10, 10, 25, 25);
            [testView setNeedsDisplayInRect:invalidatedRegion];
            [testView.layer displayIfNeeded];

            // make sure that -drawRect: was called only with the rectangle we
            // invalidated
            expect(testView.drawRectRegion).toEqual(invalidatedRegion);
        });

        it(@"calls layoutSubviews when settings its frame", ^{
            // Even if layoutSubviews is called on init, we clear side effects here.
            [testView reset];

            testView.frame = CGRectMake(10, 10, 25, 25);
            expect(testView.layoutSubviewsInvoked).toBeTruthy();
        });

        it(@"calls layoutSubviews when setting its bounds", ^{
            // Even if layoutSubviews is called on init, we clear side effects here.
            [testView reset];

            testView.bounds = CGRectMake(0, 0, 25, 25);
            expect(testView.layoutSubviewsInvoked).toBeTruthy();
        });

        it(@"can animate with VELViewAnimationOptionLayoutSubviews", ^{
            [testView reset];

            [VELView animateWithDuration:0 options:VELViewAnimationOptionLayoutSubviews animations:^{
                expect(testView.layoutSubviewsInvoked).toBeFalsy();

                testView.backgroundColor = [NSColor blueColor];
            }];

            expect(testView.layoutSubviewsInvoked).toBeTruthy();
        });

        it(@"can animate VELViewAnimationOptionLayoutSuperview", ^{
            [testView addSubview:view];
            [testView reset];

            [VELView animateWithDuration:0 options:VELViewAnimationOptionLayoutSuperview animations:^{
                expect(testView.layoutSubviewsInvoked).toBeFalsy();

                view.backgroundColor = [NSColor blueColor];
            }];

            expect(testView.layoutSubviewsInvoked).toBeTruthy();
        });

        describe(@"inserts subviews at a specific index", ^{
            __block TestView *subview1;
            __block TestView *subview2;
            __block TestView *subview3;

            before(^{
                subview1 = [[TestView alloc] init];
                subview1.nextSuperview = view;
                subview2 = [[TestView alloc] init];
                subview2.nextSuperview = view;
                subview3 = [[TestView alloc] init];
                subview3.nextSuperview = view;
            });

            it(@"can insert a subview at index 0", ^{
                [view insertSubview:subview1 atIndex:0];
                expect([view.subviews objectAtIndex:0]).toEqual(subview1);

                expect(subview1.willMoveToSuperviewInvoked).toBeTruthy();
                expect(subview1.didMoveFromSuperviewInvoked).toBeTruthy();
                expect(subview1.willMoveToWindowInvoked).toBeFalsy();
                expect(subview1.didMoveFromWindowInvoked).toBeFalsy();

            });

            it(@"can insert a subview at index 1", ^{
                [view insertSubview:subview1 atIndex:0];
                [view insertSubview:subview2 atIndex:1];
                expect([view.subviews objectAtIndex:1]).toEqual(subview2);
            });

            it(@"can insert an existing subview into index1", ^{
                [view insertSubview:subview1 atIndex:0];
                [view insertSubview:subview2 atIndex:1];
                [view insertSubview:subview3 atIndex:2];

                expect([view.subviews objectAtIndex:0]).toEqual(subview1);
                expect([view.subviews objectAtIndex:1]).toEqual(subview2);
                expect([view.subviews objectAtIndex:2]).toEqual(subview3);

                [subview2 reset];
                subview2.nextSuperview = view;
                [view insertSubview:subview2 atIndex:0];

                NSArray *expectedSubviews = [NSArray arrayWithObjects:subview2, subview1, subview3, nil];
                expect(view.subviews).toEqual(expectedSubviews);

                expect(subview2.willMoveToSuperviewInvoked).toBeFalsy();
                expect(subview2.didMoveFromSuperviewInvoked).toBeFalsy();
                expect(subview2.willMoveToWindowInvoked).toBeFalsy();
                expect(subview2.didMoveFromWindowInvoked).toBeFalsy();
            });

            it(@"can insert the same subview twice", ^{
                [view insertSubview:subview1 atIndex:0];
                [view insertSubview:subview1 atIndex:1];
            });
        });

        // BS-1324
        it(@"should not enter an infinite loop when setting the geometry of subviews in layoutSubviews", ^{
            FrameSettingView *view = [[FrameSettingView alloc] init];
            expect(view).not.toBeNil();

            [view.layer setNeedsLayout];
            [view.layer layoutIfNeeded];
        });
    });

    describe(@"<NSEditor> support", ^{
        it(@"should return success for commitEditing", ^{
            expect([^{
                expect([view commitEditing]).toBeTruthy();
            } copy]).toInvoke(view, @selector(commitEditingAndPerform:));
        });

        it(@"should return success for commitEditingAndReturnError:", ^{
            expect([^{
                __block NSError *error = nil;
                expect([view commitEditingAndReturnError:&error]).toBeTruthy();
                expect(error).toBeNil();
            } copy]).toInvoke(view, @selector(commitEditingAndPerform:));
        });

        it(@"should return success for commitEditingWithDelegate:didCommitSelector:contextInfo:", ^{
            TestEditorDelegate *delegate = [[TestEditorDelegate alloc] init];
            expect([^{
                expect([^{
                    [view commitEditingWithDelegate:delegate didCommitSelector:@selector(editor:didCommit:contextInfo:) contextInfo:NULL];
                } copy]).toInvoke(delegate, @selector(editor:didCommit:contextInfo:));
            } copy]).toInvoke(view, @selector(commitEditingAndPerform:));
        });

        it(@"should not do anything for discardEditing", ^{
            [view discardEditing];
        });
    });
});

SpecEnd

@implementation TestView
@synthesize willMoveToSuperviewInvoked = m_willMoveToSuperviewInvoked;
@synthesize willMoveToWindowInvoked = m_willMoveToWindowInvoked;
@synthesize didMoveFromSuperviewInvoked = m_didMoveFromSuperviewInvoked;
@synthesize didMoveFromWindowInvoked = m_didMoveFromWindowInvoked;
@synthesize viewHierarchyDidChangeInvoked = m_viewHierarchyDidChangeInvoked;
@synthesize oldSuperview = m_oldSuperview;
@synthesize oldWindow = m_oldWindow;
@synthesize nextSuperview = m_nextSuperview;
@synthesize nextWindow = m_nextWindow;
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

- (void)viewHierarchyDidChange {
    [super viewHierarchyDidChange];
    self.viewHierarchyDidChangeInvoked = YES;
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
    self.viewHierarchyDidChangeInvoked = NO;
    self.oldSuperview = nil;
    self.oldWindow = nil;
    self.nextSuperview = nil;
    self.nextWindow = nil;
    self.drawRectRegion = CGRectNull;
    self.layoutSubviewsInvoked = NO;
}

@end

@implementation FrameSettingView
@synthesize subview = m_subview;

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_subview = [[VELView alloc] initWithFrame:CGRectMake(10, 10, 20, 20)];
    [self addSubview:m_subview];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // setting subview geometry properties in here should not result in an infinite loop
    self.subview.frame = CGRectInset(self.subview.frame, -1, -1);
    self.subview.bounds = CGRectInset(self.subview.bounds, -1, -1);
    self.subview.center = CGPointMake(self.subview.center.x + 1, self.subview.center.y + 1);
}

@end

@implementation TestEditorDelegate

- (void)editor:(id)editor didCommit:(BOOL)didCommit contextInfo:(void *)contextInfo; {
}

@end

@implementation OddFittingSizeView

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(13, 27);
}

@end
