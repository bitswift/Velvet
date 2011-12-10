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

@end
