//
//  VELAppKitAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 06.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELAppKitAdditionsTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@implementation VELAppKitAdditionsTests

- (void)testNSEqualEdgeInsets {
    NSEdgeInsets insets = NSEdgeInsetsMake(2, 3, 4, 5);

    NSEdgeInsets equalInsets = NSEdgeInsetsMake(2, 3, 4, 5);
    STAssertTrue(NSEqualEdgeInsets(insets, equalInsets), @"");

    NSEdgeInsets inequalInsets = NSEdgeInsetsMake(0, 0, 4, 5);
    STAssertFalse(NSEqualEdgeInsets(insets, inequalInsets), @"");
}

@end
