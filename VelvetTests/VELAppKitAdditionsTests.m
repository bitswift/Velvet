//
//  VELAppKitAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 06.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

SpecBegin(VELAppKitAdditionsTests)

describe(@"VELAppKitAdditions", ^{
    it(@"can compare NSEdgeInets", ^{
        NSEdgeInsets insets = NSEdgeInsetsMake(2, 3, 4, 5);

        NSEdgeInsets equalInsets = NSEdgeInsetsMake(2, 3, 4, 5);
        expect(NSEqualEdgeInsets(insets, equalInsets)).toBeTruthy();

        NSEdgeInsets inequalInsets = NSEdgeInsetsMake(0, 0, 4, 5);
        expect(NSEqualEdgeInsets(insets, inequalInsets)).toBeFalsy();
    });
});

SpecEnd
