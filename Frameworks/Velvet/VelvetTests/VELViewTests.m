//
//  VELViewTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 08.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELViewTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@implementation VELViewTests

- (void)testSizeThatFits {
    VELView *view = [[VELView alloc] init];
    STAssertNotNil(view, @"");

    VELView *subview = [[VELView alloc] initWithFrame:CGRectMake(100, 0, 300, 200)];
    STAssertNotNil(subview, @"");
    
    [view addSubview:subview];
    [view centeredSizeToFit];

    STAssertEqualsWithAccuracy(view.bounds.size.width, (CGFloat)400, 0.001, @"");
    STAssertEqualsWithAccuracy(view.bounds.size.height, (CGFloat)200, 0.001, @"");
}

- (void)testRemoveFromSuperview {
    VELView *view = [[VELView alloc] init];
    VELView *subview = [[VELView alloc] init];

    [view addSubview:subview];
    STAssertEqualObjects([subview superview], view, @"");
    STAssertEqualObjects([[view subviews] lastObject], subview, @"");

    [subview removeFromSuperview];
    STAssertNil([subview superview], @"");
    STAssertEquals([[view subviews] count], (NSUInteger)0, @"");
}

- (void)testSetSubviews {
    VELView *view = [[VELView alloc] init];

    NSMutableArray *subviews = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0;i < 4;++i) {
        [subviews addObject:[[VELView alloc] init]];
    }

    // make sure that -setSubviews: does not throw an exception
    // (such as mutation while enumerating)
    STAssertNoThrow(view.subviews = subviews, @"");

    // the two arrays should have the same objects, but should not be the same
    // array instance
    STAssertFalse(view.subviews == subviews, @"");
    STAssertEqualObjects(view.subviews, subviews, @"");

    // removing the last subview should remove the last object from the subviews
    // array
    [[subviews lastObject] removeFromSuperview];
    [subviews removeLastObject];

    STAssertEqualObjects(view.subviews, subviews, @"");

    [subviews removeLastObject];

    // calling -setSubviews: with a new array should replace the old one
    view.subviews = subviews;
    STAssertEqualObjects(view.subviews, subviews, @"");
}

@end
