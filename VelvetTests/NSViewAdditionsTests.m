//
//  NSViewAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 15.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

SpecBegin(NSViewAdditions)

describe(@"NSViewAdditions", ^{
    __block VELWindow *window;
    __block NSView *theNSView;

    before(^{
        window = [[VELWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 500)];
        theNSView = [[NSView alloc] initWithFrame:CGRectMake(20, 50, 100, 200)];
    });

    it(@"conforms to VELBridgedView", ^{
        expect([NSView class]).toConformTo(@protocol(VELBridgedView));
        expect(theNSView).toConformTo(@protocol(VELBridgedView));
    });

    describe(@"Geometry conversion", ^{
        before(^{
            [window.contentView addSubview:theNSView];
        });

        it(@"converts from window point", ^{
            CGPoint point = CGPointMake(125, 255);

            expect([theNSView convertFromWindowPoint:point]).toEqual([theNSView convertPoint:point fromView:nil]);
        });

        it(@"converts to window point", ^{
            CGPoint point = CGPointMake(125, 255);

            expect([theNSView convertToWindowPoint:point]).toEqual([theNSView convertPoint:point toView:nil]);
        });

        it(@"converts to window rect", ^{
            CGRect rect = CGRectMake(30, 60, 145, 275);

            expect([theNSView convertToWindowRect:rect]).toEqual([theNSView convertRect:rect toView:nil]);
        });

        it(@"converts from window rect", ^{
            CGRect rect = CGRectMake(30, 60, 145, 275);

            expect([theNSView convertFromWindowRect:rect]).toEqual([theNSView convertRect:rect fromView:nil]);
        });
    });

    it(@"can have a hostView", ^{
        expect(theNSView.hostView).toBeNil();

        VELNSView *hostView = [[VELNSView alloc] init];
        theNSView.hostView = hostView;

        expect(theNSView.hostView).toEqual(hostView);
    });

    it(@"does not throw an exception in -ancestorDidLayout", ^{
        [theNSView ancestorDidLayout];
    });

    it(@"ancestorNSVelvetView is set to the first NSVelvetView in the hierarchy", ^{
        NSVelvetView *theNSVelvetView = [[NSVelvetView alloc] initWithFrame:CGRectZero];
        [theNSVelvetView addSubview:theNSView];
        expect(theNSView.ancestorNSVelvetView).toEqual(theNSVelvetView);
    });

    it(@"ancestorScrollView returns the first NSClipView in the hierarchy", ^{
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
        expect(scrollView.ancestorScrollView).toEqual(scrollView);

        NSView *view = [[NSView alloc] initWithFrame:CGRectZero];

        [scrollView setDocumentView:view];

        expect(view.ancestorScrollView).toEqual(scrollView.contentView);
    });

    it(@"implements willMoveToNSVelvetView and didMoveFromNSVelvetView", ^{
        NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
        [view willMoveToNSVelvetView:nil];
        [view didMoveFromNSVelvetView:nil];
    });

    it(@"implements descendantViewAtPoint", ^{
        NSView *superview = [[NSView alloc] initWithFrame:CGRectMake(20, 20, 80, 80)];

        NSView *subview = [[NSView alloc] initWithFrame:CGRectMake(50, 30, 100, 150)];
        [superview addSubview:subview];

        CGPoint subviewPoint = CGPointMake(51, 31);
        expect([superview descendantViewAtPoint:subviewPoint]).toEqual(subview);

        CGPoint superviewPoint = CGPointMake(49, 29);
        expect([superview descendantViewAtPoint:superviewPoint]).toEqual(superview);

        CGPoint outsidePoint = CGPointMake(49, 200);
        expect([superview descendantViewAtPoint:outsidePoint]).toBeNil();
    });

    describe(@"pointInside", ^{
        __block NSView *view = nil;

        before(^{
            view = [[NSView alloc] initWithFrame:CGRectMake(40, 40, 80, 80)];
        });

        it(@"returns true when given a point inside the receiver's bounds", ^{
            CGPoint insidePoint = CGPointMake(51, 31);
            expect([view pointInside:insidePoint]).toBeTruthy();
        });

        it(@"returns false when given a point outside the receiver's bounds", ^{
            CGPoint outsidePoint = CGPointMake(49, 200);
            expect([view pointInside:outsidePoint]).toBeFalsy();
        });

        it(@"returns true when in a superview and given a point inside the receiver's bounds", ^{
            [theNSView addSubview:view];

            CGPoint insidePoint = CGPointMake(51, 31);
            expect([view pointInside:insidePoint]).toBeTruthy();
        });

        it(@"returns false when in a superview and given a point outside the receiver's bounds", ^{
            [theNSView addSubview:view];

            CGPoint outsidePoint = CGPointMake(49, 200);
            expect([view pointInside:outsidePoint]).toBeFalsy();
        });
    });
});

SpecEnd
