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

- (void)testRectDifferenceWithoutIntersection {
    CGRect rect = CGRectMake(0, 0, 50, 50);
    CGRect subtraction = CGRectMake(100, 100, 50, 50);

    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(result, rect), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(rect));
}

- (void)testRectDifferenceWithEqualRects {
    CGRect rect = CGRectMake(0, 0, 50, 50);
    CGRect subtraction = CGRectMake(0, 0, 50, 50);

    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectIsEmpty(result), @"%@ should be empty", NSStringFromRect(result));
}

- (void)testRectDifferenceWithContainment {
    CGRect rect = CGRectMake(25, 25, 50, 50);
    CGRect subtraction = CGRectMake(0, 0, 100, 100);

    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectIsNull(result), @"%@ should be null", NSStringFromRect(result));
}

- (void)testRectDifferenceMinXMinY {
    CGRect rect = CGRectMake(250, 250, 500, 500);
    CGRect subtraction = CGRectMake(0, 0, 500, 500);

    CGRect expectedResult = CGRectMake(500, 500, 250, 250);
    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testRectDifferenceMinXMaxY {
    CGRect rect = CGRectMake(250, 250, 500, 500);
    CGRect subtraction = CGRectMake(0, 500, 500, 500);

    CGRect expectedResult = CGRectMake(500, 250, 250, 250);
    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testRectDifferenceMaxXMinY {
    CGRect rect = CGRectMake(250, 250, 500, 500);
    CGRect subtraction = CGRectMake(500, 0, 500, 500);

    CGRect expectedResult = CGRectMake(250, 500, 250, 250);
    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testRectDifferenceMaxXMaxY {
    CGRect rect = CGRectMake(250, 250, 500, 500);
    CGRect subtraction = CGRectMake(500, 500, 500, 500);

    CGRect expectedResult = CGRectMake(250, 250, 250, 250);
    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testRectDifferenceInside {
    CGRect rect = CGRectMake(0, 0, 1000, 1000);
    CGRect subtraction = CGRectMake(250, 250, 500, 500);

    // should return the result closest to the origin
    CGRect expectedResult = CGRectMake(0, 0, 250, 250);

    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testRectDifferenceInsideUneven {
    CGRect rect = CGRectMake(0, 0, 1000, 1000);
    CGRect subtraction = CGRectMake(100, 100, 500, 500);

    // should return the largest result
    CGRect expectedResult = CGRectMake(600, 600, 400, 400);

    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testRectDifferenceMinXSide {
    CGRect rect = CGRectMake(250, 250, 500, 500);
    CGRect subtraction = CGRectMake(250, 250, 250, 500);

    CGRect expectedResult = CGRectMake(500, 250, 250, 500);
    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testRectDifferenceMinYSide {
    CGRect rect = CGRectMake(250, 250, 500, 500);
    CGRect subtraction = CGRectMake(250, 250, 500, 250);

    CGRect expectedResult = CGRectMake(250, 500, 500, 250);
    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testRectDifferenceMaxXSide {
    CGRect rect = CGRectMake(250, 250, 500, 500);
    CGRect subtraction = CGRectMake(500, 250, 250, 500);

    CGRect expectedResult = CGRectMake(250, 250, 250, 500);
    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
}

- (void)testRectDifferenceMaxYSide {
    CGRect rect = CGRectMake(250, 250, 500, 500);
    CGRect subtraction = CGRectMake(250, 500, 500, 250);

    CGRect expectedResult = CGRectMake(250, 250, 500, 250);
    CGRect result = CGRectDifference(rect, subtraction);
    STAssertTrue(CGRectEqualToRect(expectedResult, result), @"%@ should be equal to %@", NSStringFromRect(result), NSStringFromRect(expectedResult));
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
