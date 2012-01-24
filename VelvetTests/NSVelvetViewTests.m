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
        NSVelvetView *velvetView = window.contentView;
        VELView *view = [[VELView alloc] initWithFrame:CGRectMake(50, 30, 100, 150)];
        [velvetView.guestView addSubview:view];

        CGPoint guestSubviewPoint = CGPointMake(51, 31);
        expect([velvetView descendantViewAtPoint:guestSubviewPoint]).toEqual(view);


        CGPoint guestViewPoint = CGPointMake(49, 29);
        expect([velvetView descendantViewAtPoint:guestViewPoint]).toEqual(view);

        CGPoint outsidePoint = CGPointMake(49, 1000);
        expect([velvetView descendantViewAtPoint:outsidePoint]).toBeNil();
    });
});

SpecEnd

@implementation TestVELView

- (void)didMoveFromNSVelvetView:(NSVelvetView *)view {
    [super didMoveFromNSVelvetView:view];

    // The NSVelvetView's guestView should be self.
    NSAssert(self.ancestorNSVelvetView.guestView == self, @"");
}

@end
