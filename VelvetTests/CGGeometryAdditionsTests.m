//
//  CGGeometryAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "CGGeometryAdditionsTests.h"
#import <Velvet/Velvet.h>

@implementation CGGeometryAdditionsTests

- (void)testDivideExcludingIntersectionWithoutIntersection {
    CGRect rect = CGRectMake(0, 0, 50, 50);
    CGRect choppingRect = CGRectMake(100, 100, 50, 50);

    CGRect slice, remainder;
    CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, CGRectMinXEdge);

    STAssertTrue(CGRectEqualToRect(slice, rect), @"%@ should be equal to %@", NSStringFromRect(slice), NSStringFromRect(rect));
    STAssertTrue(CGRectIsNull(remainder), @"%@ should be null", NSStringFromRect(remainder));
}

- (void)testDivideExcludingIntersectionWithEqualRects {
    CGRect rect = CGRectMake(0, 0, 50, 50);
    CGRect choppingRect = CGRectMake(0, 0, 50, 50);

    CGRect slice, remainder;
    CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, CGRectMinXEdge);

    STAssertTrue(CGRectIsEmpty(slice), @"%@ should be empty", NSStringFromRect(slice));
    STAssertTrue(CGRectIsEmpty(remainder), @"%@ should be empty", NSStringFromRect(remainder));
}

- (void)testDivideExcludingIntersectionNullSlice {
    CGRect rect = CGRectMake(0, 0, 50, 50);
    CGRect choppingRect = CGRectMake(25, 25, 10, 10);

    CGRect remainder;
    CGRectDivideExcludingIntersection(rect, NULL, &remainder, choppingRect, CGRectMinXEdge);

    CGRect expectedRemainder = CGRectMake(35, 0, 15, 50);
    STAssertTrue(CGRectEqualToRect(remainder, expectedRemainder), @"%@ should be equal to %@", NSStringFromRect(remainder), NSStringFromRect(expectedRemainder));
}

- (void)testDivideExcludingIntersectionNullRemainder {
    CGRect rect = CGRectMake(0, 0, 50, 50);
    CGRect choppingRect = CGRectMake(25, 25, 10, 10);

    CGRect slice;
    CGRectDivideExcludingIntersection(rect, &slice, NULL, choppingRect, CGRectMaxXEdge);

    CGRect expectedSlice = CGRectMake(35, 0, 15, 50);
    STAssertTrue(CGRectEqualToRect(slice, expectedSlice), @"%@ should be equal to %@", NSStringFromRect(slice), NSStringFromRect(expectedSlice));
}

- (void)testDivideExcludingIntersectionWithContainment {
    CGRect rect = CGRectMake(25, 25, 50, 50);
    CGRect choppingRect = CGRectMake(0, 0, 100, 100);

    CGRect slice, remainder;
    CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, CGRectMinXEdge);

    STAssertTrue(CGRectIsNull(slice), @"%@ should be null", NSStringFromRect(slice));
    STAssertTrue(CGRectIsNull(remainder), @"%@ should be null", NSStringFromRect(remainder));
}

- (void)testDivideExcludingIntersectionMinXEdge {
    CGRect rect = CGRectMake(0, 0, 100, 100);
    CGRect choppingRect = CGRectMake(20, 25, 50, 65);

    CGRectEdge edge = CGRectMinXEdge;
    CGRect expectedSlice = CGRectMake(0, 0, 20, 100);
    CGRect expectedRemainder = CGRectMake(70, 0, 30, 100);

    CGRect slice, remainder;
    CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, edge);

    STAssertTrue(CGRectEqualToRect(slice, expectedSlice), @"%@ should be equal to %@", NSStringFromRect(slice), NSStringFromRect(expectedSlice));
    STAssertTrue(CGRectEqualToRect(remainder, expectedRemainder), @"%@ should be equal to %@", NSStringFromRect(remainder), NSStringFromRect(expectedRemainder));
}

- (void)testDivideExcludingIntersectionMinYEdge {
    CGRect rect = CGRectMake(0, 0, 100, 100);
    CGRect choppingRect = CGRectMake(20, 25, 50, 65);

    CGRectEdge edge = CGRectMinYEdge;
    CGRect expectedSlice = CGRectMake(0, 0, 100, 25);
    CGRect expectedRemainder = CGRectMake(0, 90, 100, 10);

    CGRect slice, remainder;
    CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, edge);

    STAssertTrue(CGRectEqualToRect(slice, expectedSlice), @"%@ should be equal to %@", NSStringFromRect(slice), NSStringFromRect(expectedSlice));
    STAssertTrue(CGRectEqualToRect(remainder, expectedRemainder), @"%@ should be equal to %@", NSStringFromRect(remainder), NSStringFromRect(expectedRemainder));
}

- (void)testDivideExcludingIntersectionMaxXEdge {
    CGRect rect = CGRectMake(0, 0, 100, 100);
    CGRect choppingRect = CGRectMake(20, 25, 50, 65);

    CGRectEdge edge = CGRectMaxXEdge;
    CGRect expectedSlice = CGRectMake(70, 0, 30, 100);
    CGRect expectedRemainder = CGRectMake(0, 0, 20, 100);

    CGRect slice, remainder;
    CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, edge);

    STAssertTrue(CGRectEqualToRect(slice, expectedSlice), @"%@ should be equal to %@", NSStringFromRect(slice), NSStringFromRect(expectedSlice));
    STAssertTrue(CGRectEqualToRect(remainder, expectedRemainder), @"%@ should be equal to %@", NSStringFromRect(remainder), NSStringFromRect(expectedRemainder));
}

- (void)testDivideExcludingIntersectionMaxYEdge {
    CGRect rect = CGRectMake(0, 0, 100, 100);
    CGRect choppingRect = CGRectMake(20, 25, 50, 65);

    CGRectEdge edge = CGRectMaxYEdge;
    CGRect expectedSlice = CGRectMake(0, 90, 100, 10);
    CGRect expectedRemainder = CGRectMake(0, 0, 100, 25);

    CGRect slice, remainder;
    CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, edge);

    STAssertTrue(CGRectEqualToRect(slice, expectedSlice), @"%@ should be equal to %@", NSStringFromRect(slice), NSStringFromRect(expectedSlice));
    STAssertTrue(CGRectEqualToRect(remainder, expectedRemainder), @"%@ should be equal to %@", NSStringFromRect(remainder), NSStringFromRect(expectedRemainder));
}

- (void)testChop {
    CGRect rect = CGRectMake(100, 100, 100, 100);

    CGRect result = CGRectChop(rect, 25, CGRectMaxXEdge);
    CGRect expectedResult = CGRectMake(100, 100, 75, 100);
    STAssertTrue(CGRectEqualToRect(result, expectedResult), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testGrow {
    CGRect rect = CGRectMake(100, 100, 100, 100);

    CGRect result = CGRectGrow(rect, 25, CGRectMinXEdge);
    CGRect expectedResult = CGRectMake(75, 100, 125, 100);
    STAssertTrue(CGRectEqualToRect(result, expectedResult), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

@end
