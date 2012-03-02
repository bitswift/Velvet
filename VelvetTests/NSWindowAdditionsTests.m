//
//  NSWindowAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 15.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

SpecBegin(NSWindowAdditions)

    it(@"Initializes with contentRect", ^{
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 500)];

        expect(window).not.toBeNil();

        CGRect contentRect = [window contentRectForFrameRect:window.frame];
        expect(contentRect.size).toEqual(CGSizeMake(500, 500));
    });

    it(@"Initializes with content rect and style", ^{
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 500) styleMask:NSBorderlessWindowMask];
        expect(window).not.toBeNil();

        CGRect contentRect = [window contentRectForFrameRect:window.frame];
        expect(contentRect.size).toEqual(CGSizeMake(500, 500));
    });

    describe(@"responder chain additions", ^{
        __block NSWindow *window;

        __block NSView *responderView;
        __block NSView *superview;
        __block NSView *siblingView;

        before(^{
            window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 200, 200)];

            responderView = [[NSView alloc] initWithFrame:CGRectZero];
            siblingView = [[NSView alloc] initWithFrame:CGRectZero];

            superview = [[NSView alloc] initWithFrame:CGRectZero];
            [superview addSubview:responderView];
            [superview addSubview:siblingView];
            [window.contentView addSubview:superview];

            expect([window makeFirstResponder:responderView]).toBeTruthy();
            expect(window.firstResponder).toEqual(responderView);
        });

        it(@"should have no effect making the responderView the first responder", ^{
            expect([window makeFirstResponderIfNotInResponderChain:responderView]).toBeTruthy();
            expect(window.firstResponder).toEqual(responderView);
        });

        it(@"should have no effect making the superview of the responderView the first responder", ^{
            expect([window makeFirstResponderIfNotInResponderChain:superview]).toBeTruthy();
            expect(window.firstResponder).toEqual(responderView);
        });

        it(@"should make a sibling of the responderView the first responder", ^{
            expect([window makeFirstResponderIfNotInResponderChain:siblingView]).toBeTruthy();
            expect(window.firstResponder).toEqual(siblingView);
        });

        it(@"should clear first responder", ^{
            expect([window makeFirstResponderIfNotInResponderChain:nil]).toBeTruthy();
            expect(window.firstResponder).toEqual(window);
        });
    });

SpecEnd
