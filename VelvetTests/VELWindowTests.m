//
//  VELWindowTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELWindowTests.h"
#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

@interface VELWindowTests ()
- (VELWindow *)newWindow;
@end

SpecBegin(VELWindow)
   __block VELWindow *window;

    before(^{
        window = [[VELWindow alloc]
            initWithContentRect:CGRectMake(100, 100, 500, 500)
            styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
            backing:NSBackingStoreBuffered
            defer:NO
                  ];
    });

    it(@"initializes", ^{
        expect(window).not.toBeNil();
    });

    it(@"initializes with a nil screen", ^{
        VELWindow *window = [[VELWindow alloc]
            initWithContentRect:CGRectMake(100, 100, 500, 500)
            styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
            backing:NSBackingStoreBuffered
            defer:NO
            screen:nil
        ];

        expect(window).not.toBeNil();
    });

    it(@"initializes with a content view", ^{
        NSVelvetView *hostView = window.contentView;
        expect(hostView).not.toBeNil();
        expect(hostView).toBeKindOf([NSVelvetView class]);
    });

    it(@"initializes with a root view", ^{
        VELView *rootView = window.rootView;
        expect(rootView).not.toBeNil();

        expect(rootView.hostView).toEqual(window.contentView);
    });

SpecEnd
