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

describe(@"NSWindowAdditions", ^{
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
});

SpecEnd
