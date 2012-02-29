//
//  NSClipViewAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.02.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/NSClipView+VELScrollViewAdditions.h>

SpecBegin(NSClipViewAdditions)

    __block NSClipView *clipView;

    before(^{
        clipView = [[NSClipView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
        clipView.documentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1000, 1000)];
    });
    
    it(@"should implement <VELScrollView>", ^{
        expect(clipView).toConformTo(@protocol(VELScrollView));
    });

    it(@"should scroll to point", ^{
        CGPoint point = CGPointMake(200, 100);
        [clipView scrollToPoint:point];

        expect(clipView.documentVisibleRect.origin).isGoing.toEqual(point);
        expect(clipView.documentVisibleRect.size).isGoing.toEqual(clipView.bounds.size);
    });

    it(@"should scroll from bottom-left to include rectangle", ^{
        CGRect rect = CGRectMake(100, 200, 75, 50);
        [clipView scrollToIncludeRect:rect];

        expect(clipView.documentVisibleRect).isGoing.toEqual(CGRectMake(75, 150, 100, 100));
    });

    it(@"should scroll from bottom-right to include rectangle", ^{
        CGPoint point = CGPointMake(
            CGRectGetMaxX([clipView.documentView bounds]) - CGRectGetWidth(clipView.bounds),
            0
        );

        [clipView scrollToPoint:point];
        expect(clipView.documentVisibleRect.origin).isGoing.toEqual(point);

        CGRect rect = CGRectMake(100, 200, 75, 50);
        [clipView scrollToIncludeRect:rect];

        expect(clipView.documentVisibleRect).isGoing.toEqual(CGRectMake(100, 150, 100, 100));
    });

    it(@"should scroll from top-right to include rectangle", ^{
        CGPoint point = CGPointMake(
            CGRectGetMaxX([clipView.documentView bounds]) - CGRectGetWidth(clipView.bounds),
            CGRectGetMaxY([clipView.documentView bounds]) - CGRectGetHeight(clipView.bounds)
        );

        [clipView scrollToPoint:point];
        expect(clipView.documentVisibleRect.origin).isGoing.toEqual(point);

        CGRect rect = CGRectMake(100, 200, 75, 50);
        [clipView scrollToIncludeRect:rect];

        expect(clipView.documentVisibleRect).isGoing.toEqual(CGRectMake(100, 200, 100, 100));
    });

    it(@"should scroll from top-left to include rectangle", ^{
        CGPoint point = CGPointMake(
            0,
            CGRectGetMaxY([clipView.documentView bounds]) - CGRectGetHeight(clipView.bounds)
        );

        [clipView scrollToPoint:point];
        expect(clipView.documentVisibleRect.origin).isGoing.toEqual(point);

        CGRect rect = CGRectMake(100, 200, 75, 50);
        [clipView scrollToIncludeRect:rect];

        expect(clipView.documentVisibleRect).isGoing.toEqual(CGRectMake(75, 200, 100, 100));
    });

    it(@"should scroll to include already-visible rectangle", ^{
        CGRect visibleRect = clipView.documentVisibleRect;

        CGRect rect = CGRectMake(0, 0, 50, 75);
        [clipView scrollToIncludeRect:rect];

        expect(clipView.documentVisibleRect).toEqual(visibleRect);
    });

    it(@"should scroll to include rectangle too large", ^{
        CGRect rect = CGRectMake(100, 200, 300, 400);
        [clipView scrollToIncludeRect:rect];

        expect(CGRectContainsRect(rect, clipView.documentVisibleRect)).toBeTruthy();
    });

SpecEnd
