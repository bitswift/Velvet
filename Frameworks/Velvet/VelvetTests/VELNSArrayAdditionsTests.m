//
//  VELNSArrayAdditionsTests.m
//  Velvet
//
//  Created by Josh Vera on 12/7/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELNSArrayAdditionsTests.h"
#import "NSArray+HigherOrderAdditions.h"

@interface VELNSArrayAdditionsTests ()

- (void)testFilteringWithOptions:(NSEnumerationOptions)opts;

@end

@implementation VELNSArrayAdditionsTests

// All code under test must be linked into the Unit Test bundle
- (void)testFilter {
    NSArray *array = [NSArray arrayWithObjects:@"foo", @"bar", @"baz", nil];

    NSArray *filteredArray = [array filterUsingBlock:^(NSString *string) {
        return [string isEqualToString:@"bar"];
    }];

    STAssertEqualObjects(filteredArray, [NSArray arrayWithObject:@"bar"], @"");
}

- (void)testFilteringEmptyArray {
    NSArray *array = [NSArray array];

    NSArray *filteredArray = [array filterUsingBlock:^(NSString *string) {
        return [string isEqualToString:@"bar"];
    }];

    STAssertEqualObjects(filteredArray, [NSArray array], @"");
}

- (void)testFilteringWithoutSuccess {
    NSArray *array = [NSArray arrayWithObjects:@"foo", @"bar", @"baz", nil];

    NSArray *filteredArray = [array filterUsingBlock:^(NSString *string) {
        return [string isEqualToString:@"quux"];
    }];

    STAssertEqualObjects(filteredArray, [NSArray array], @"");
}

- (void)testFilteringConcurrently {
    [self testFilteringWithOptions:NSEnumerationConcurrent];
}

- (void)testFilteringReverse {
    [self testFilteringWithOptions:NSEnumerationReverse];
}

- (void)testFilteringWithOptions:(NSEnumerationOptions)opts {
    NSArray *array = [NSArray arrayWithObjects:@"foo", @"bar", @"baz", nil];

    NSArray *filteredArray = [array filterWithOptions:opts usingBlock:^(NSString *string) {
        if ([string isEqualToString:@"bar"] || [string isEqualToString:@"foo"])
            return YES;
        else
            return NO;
    }];

    NSArray *testArray = [NSArray arrayWithObjects:@"foo", @"bar", nil];
    STAssertEqualObjects(filteredArray, testArray, @"");
}

@end
