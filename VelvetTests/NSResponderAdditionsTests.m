//
//  NSResponderAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>

SpecBegin(NSResponderAdditions)
    
    __block NSView *view;

    before(^{
        view = [[NSView alloc] initWithFrame:CGRectZero];
    });

    it(@"should be next responder of self", ^{
        expect([view isNextResponderOf:view]).toBeTruthy();
    });

    it(@"should be next responder of subview", ^{
        NSView *superview = [[NSView alloc] initWithFrame:CGRectZero];
        [superview addSubview:view];

        expect([superview isNextResponderOf:view]).toBeTruthy();

        // the view should not be a next responder of its superview
        expect([view isNextResponderOf:superview]).toBeFalsy();
    });

    it(@"should be next responder of descendant view", ^{
        NSView *superview = [[NSView alloc] initWithFrame:CGRectZero];
        [superview addSubview:view];

        NSView *ancestor = [[NSView alloc] initWithFrame:CGRectZero];
        [ancestor addSubview:superview];

        expect([ancestor isNextResponderOf:view]).toBeTruthy();
    });

    it(@"should not be next responder of unrelated view", ^{
        NSView *sibling = [[NSView alloc] initWithFrame:CGRectZero];
        expect([sibling isNextResponderOf:view]).toBeFalsy();
    });

SpecEnd
