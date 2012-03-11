//
//  NSVelvetViewTests.m
//  Velvet
//
//  Created by Josh Vera on 1/6/12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@interface TestVELView : VELView
@end

SpecBegin(NSVelvetView)

describe(@"NSVelvetView", ^{
    __block VELWindow *window;

    before(^{
        window = [[VELWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 500)];
    });

    it(@"can set the guest view", ^{
        TestVELView *containerView = [[TestVELView alloc] init];
        window.contentView.guestView = containerView;

        expect(window.contentView.guestView).toEqual(containerView);
    });

    it(@"should set its rootView's nextResponder to the contentView", ^{
        expect(window.rootView.nextResponder).toEqual(window.contentView);

        VELView *view = [[VELView alloc] init];
        window.rootView = view;

        expect(view.nextResponder).toEqual(window.contentView);
    });

    it(@"has a nextResponder which is the window", ^{
        expect(window.contentView.nextResponder).toEqual(window);
    });

    it(@"conforms to VELBridgedView", ^{
        expect(window.contentView).toConformTo(@protocol(VELBridgedView));
    });

    it(@"conforms to VELHostView", ^{
        expect(window.contentView).toConformTo(@protocol(VELHostView));
    });

    it(@"should be its ancestorNSVelvetView", ^{
        expect(window.contentView.ancestorNSVelvetView).toEqual(window.contentView);
    });

    describe(@"descendantViewAtPoint", ^{
        __block NSVelvetView *velvetView;
        __block VELView *view;

        before(^{
            velvetView = window.contentView;
            view = [[VELView alloc] initWithFrame:CGRectMake(50, 30, 100, 150)];
            [velvetView.guestView addSubview:view];
        });


        it(@"returns its guestView's subview when the given point is inside the subview's bounds", ^{
            CGPoint guestSubviewPoint = CGPointMake(51, 31);
            expect([velvetView descendantViewAtPoint:guestSubviewPoint]).toEqual(view);
        });

        it(@"returns its guestView when the given point is inside the guestView's bounds", ^{
            CGPoint guestViewPoint = CGPointMake(49, 29);
            expect([velvetView descendantViewAtPoint:guestViewPoint]).toEqual(velvetView.guestView);
        });

        it(@"returns nil when the given point is outside the receiver's bounds", ^{
            CGPoint outsidePoint = CGPointMake(49, 1000);
            expect([velvetView descendantViewAtPoint:outsidePoint]).toBeNil();
        });

    });
});

SpecEnd

@implementation TestVELView

- (void)didMoveFromNSVelvetView:(NSVelvetView *)view {
    [super didMoveFromNSVelvetView:view];

    // The NSVelvetView's guestView should be self, unless it's clearing out the
    // guestView (perhaps during deallocation).
    NSAssert(self.ancestorNSVelvetView.guestView == self || !self.ancestorNSVelvetView.guestView, @"");
}

@end
