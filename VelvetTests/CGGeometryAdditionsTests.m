//
//  CGGeometryAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>

SpecBegin(CGGeometryAdditions)

describe(@"CGGeometryAdditions", ^{
    __block CGRect rect, expectedSlice, expectedRemainder, slice, remainder;

    describe(@"CGRectCenterPoint", ^{
        it(@"should return the center of a valid rectangle", ^{
            CGRect rect = CGRectMake(10, 20, 30, 40);
            expect(CGRectCenterPoint(rect)).toEqual(CGPointMake(25, 40));
        });

        it(@"should return the center of an empty rectangle", ^{
            CGRect rect = CGRectMake(10, 20, 0, 0);
            expect(CGRectCenterPoint(rect)).toEqual(CGPointMake(10, 20));
        });

        it(@"should return non-integral center points", ^{
            CGRect rect = CGRectMake(10, 20, 15, 7);
            expect(CGRectCenterPoint(rect)).toEqual(CGPointMake(17.5, 23.5));
        });
    });

    describe(@"CGRectDivideExcludingIntersection", ^{
        __block CGRect choppingRect;

        before(^{
            rect = CGRectMake(0, 0, 50, 50);
            choppingRect = CGRectMake(100, 100, 50, 50);
        });

        it(@"divides without an intersection", ^{
            CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, CGRectMinXEdge);
            expect(slice).toEqual(rect);
            expect(CGRectIsNull(remainder)).toBeTruthy();
        });

        it(@"divides with equal rects", ^{
            choppingRect = CGRectMake(0, 0, 50, 50);
            CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, CGRectMinXEdge);
            expect(CGRectIsEmpty(slice)).toBeTruthy();
            expect(CGRectIsEmpty(remainder)).toBeTruthy();
        });

        describe(@"with null values", ^{
            __block CGRect expectedRect;
            before(^{
                choppingRect = CGRectMake(25, 25, 10, 10);
                expectedRect = CGRectMake(35, 0, 15, 50);
            });

            it(@"divides with a null slice", ^{
                CGRectDivideExcludingIntersection(rect, NULL, &remainder, choppingRect, CGRectMinXEdge);

                expect(remainder).toEqual(expectedRect);
            });

            it (@"divides with a null remainder", ^{
                CGRectDivideExcludingIntersection(rect, &slice, NULL, choppingRect, CGRectMaxXEdge);
                expect(slice).toEqual(expectedRect);
            });
        });

        it(@"divides with containment", ^{
            rect = CGRectMake(25, 25, 50, 50);
            choppingRect = CGRectMake(0, 0, 100, 100);

            CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, CGRectMinXEdge);

            expect(CGRectIsNull(slice)).toBeTruthy();
            expect(CGRectIsNull(remainder)).toBeTruthy();
        });

        describe(@"with a specified edge", ^{
            __block CGRectEdge edge;
            __block CGRect expectedSlice, expectedRemainder;

            before(^{
                rect = CGRectMake(0, 0, 100, 100);
                choppingRect = CGRectMake(20, 25, 50, 65);
            });

            it(@"divides from MinXEdge", ^{
                edge = CGRectMinXEdge;
                expectedSlice = CGRectMake(0, 0, 20, 100);
                expectedRemainder = CGRectMake(70, 0, 30, 100);
            });

            it(@"divides from MinYEdge", ^{
                edge = CGRectMinYEdge;
                expectedSlice = CGRectMake(0, 0, 100, 25);
                expectedRemainder = CGRectMake(0, 90, 100, 10);
            });

            it(@"divides from MaxXEdge", ^{
                edge = CGRectMaxXEdge;
                expectedSlice = CGRectMake(70, 0, 30, 100);
                expectedRemainder = CGRectMake(0, 0, 20, 100);
            });

            it(@"divides from MaxYEdge", ^{
                edge = CGRectMaxYEdge;
                expectedSlice = CGRectMake(0, 90, 100, 10);
                expectedRemainder = CGRectMake(0, 0, 100, 25);
            });

            after(^{
                CGRectDivideExcludingIntersection(rect, &slice, &remainder, choppingRect, edge);

                expect(slice).toEqual(expectedSlice);
                expect(remainder).toEqual(expectedRemainder);
            });
        });
    });

    describe(@"CGRectDivideWithPadding", ^{
        before(^{
            rect = CGRectMake(50, 50, 100, 100);
        });

        it(@"divides with padding", ^{
            CGRect expectedSlice = CGRectMake(50, 50, 40, 100);
            CGRect expectedRemainder = CGRectMake(90 + 10, 50, 50, 100);

            CGRectDivideWithPadding(rect, &slice, &remainder, 40, 10, CGRectMinXEdge);

            expect(slice).toEqual(expectedSlice);
            expect(remainder).toEqual(expectedRemainder);
        });

        it(@"divides with a null slice", ^{
            CGRect expectedRemainder = CGRectMake(90 + 10, 50, 50, 100);

            CGRectDivideWithPadding(rect, NULL, &remainder, 40, 10, CGRectMinXEdge);
            expect(remainder).toEqual(expectedRemainder);
        });

        it(@"divides with a null remainder", ^{
            CGRect expectedSlice = CGRectMake(50, 50, 40, 100);
            CGRectDivideWithPadding(rect, &slice, NULL, 40, 10, CGRectMinXEdge);
            expect(slice).toEqual(expectedSlice);
        });

        it(@"divides with no space for remainder", ^{
            CGRect expectedSlice = CGRectMake(50, 50, 95, 100);
            CGRectDivideWithPadding(rect, &slice, &remainder, 95, 10, CGRectMinXEdge);
            expect(slice).toEqual(expectedSlice);
            expect(CGRectIsEmpty(remainder)).toBeTruthy();
        });
    });

    describe(@"CGRectChop", ^{
        rect = CGRectMake(100, 100, 100, 100);

        CGRect result = CGRectChop(rect, 25, CGRectMaxXEdge);
        CGRect expectedResult = CGRectMake(100, 100, 75, 100);

        expect(result).toEqual(expectedResult);
    });

    describe(@"CGRectGrow", ^{
        CGRect rect = CGRectMake(100, 100, 100, 100);

        CGRect result = CGRectGrow(rect, 25, CGRectMinXEdge);
        CGRect expectedResult = CGRectMake(75, 100, 125, 100);
        expect(result).toEqual(expectedResult);
    });

    describe(@"CGRectFloor", ^{
        it(@"leaves integers untouched", ^{
            CGRect rect = CGRectMake(-10, 20, -30, 40);
            CGRect result = CGRectFloor(rect);
            expect(result).toEqual(rect);
        });

        it(@"rounds down, except in Y.", ^{
            CGRect rect = CGRectMake(10.1, 1.1, -3.4, -4.7);

            CGRect result = CGRectFloor(rect);
            CGRect expectedResult = CGRectMake(10, 2, -4, -5);
            expect(result).toEqual(expectedResult);
        });

        it(@"leaves CGRectNull untouched", ^{
            CGRect rect = CGRectNull;
            CGRect result = CGRectFloor(rect);
            expect(result).toEqual(rect);
        });

        it(@"leaves CGRectInfinite untouched", ^{
            CGRect rect = CGRectInfinite;
            CGRect result = CGRectFloor(rect);
            expect(result).toEqual(rect);
        });
    });
    
    describe(@"inverted rectangles", ^{
        it(@"should create an inverted rectangle within a containing rectangle", ^{
            CGRect containingRect = CGRectMake(0, 0, 100, 100);

            // Bottom Left
            CGRect expectedResult = CGRectMake(0, CGRectGetHeight(containingRect) - 20 - 50, 50, 50);

            CGRect result = CGRectMakeInverted(containingRect, 0, 20, 50, 50);
            expect(result).toEqual(expectedResult);
        });

        it(@"should invert a rectangle within a containing rectangle", ^{
            CGRect rect = CGRectMake(0, 20, 50, 50);
            CGRect containingRect = CGRectMake(0, 0, 100, 100);

            // Bottom Left
            CGRect expectedResult = CGRectMake(0, CGRectGetHeight(containingRect) - 20 - 50, 50, 50);

            CGRect result = CGRectInvert(containingRect, rect);
            expect(result).toEqual(expectedResult);
        });
    });

    describe(@"CGRectWithSize", ^{
        it(@"should return a rectangle with a valid size", ^{
            CGRect rect = CGRectWithSize(CGSizeMake(20, 40));
            expect(rect).toEqual(CGRectMake(0, 0, 20, 40));
        });

        it(@"should return a rectangle with zero size", ^{
            CGRect rect = CGRectWithSize(CGSizeZero);
            expect(rect).toEqual(CGRectZero);
        });
    });

    describe(@"CGPointFloor", ^{
        it(@"rounds components up and left", ^{
            CGPoint point = CGPointMake(0.5, 0.49);
            CGPoint point2 = CGPointMake(-0.5, -0.49);
            expect(CGPointEqualToPoint(CGPointFloor(point), CGPointMake(0, 1))).toBeTruthy();
            expect(CGPointEqualToPoint(CGPointFloor(point2), CGPointMake(-1, 0))).toBeTruthy();
        });
    });

    describe(@"equality with accuracy", ^{
        CGRect rect = CGRectMake(0.5, 1.5, 15, 20);
        CGFloat epsilon = 0.6;

        CGRect closeRect = CGRectMake(1, 1, 15.5, 19.75);
        CGRect farRect = CGRectMake(1.5, 11.5, 20, 20);

        it(@"compares two points that are close enough", ^{
            expect(CGPointEqualToPointWithAccuracy(rect.origin, closeRect.origin, epsilon)).toBeTruthy();
        });

        it(@"compares two points that are too far from each other", ^{
            expect(CGPointEqualToPointWithAccuracy(rect.origin, farRect.origin, epsilon)).toBeFalsy();
        });

        it(@"compares two rectangles that are close enough", ^{
            expect(CGRectEqualToRectWithAccuracy(rect, closeRect, epsilon)).toBeTruthy();
        });

        it(@"compares two rectangles that are too far from each other", ^{
            expect(CGRectEqualToRectWithAccuracy(rect, farRect, epsilon)).toBeFalsy();
        });

        it(@"compares two sizes that are close enough", ^{
            expect(CGSizeEqualToSizeWithAccuracy(rect.size, closeRect.size, epsilon)).toBeTruthy();
        });

        it(@"compares two sizes that are too far from each other", ^{
            expect(CGSizeEqualToSizeWithAccuracy(rect.size, farRect.size, epsilon)).toBeFalsy();
        });
    });

    describe(@"CGSizeScale", ^{
        it(@"should scale each component", ^{
            CGSize original = CGSizeMake(-5, 3.4);
            CGFloat scale = -3.5;
            CGSize expected = CGSizeMake(17.5, -11.9);
            expect(CGSizeScale(original, scale)).toEqual(expected);
        });
    });

    describe(@"CGPointAdd", ^{
        it(@"adds two points together, element-wise", ^{
            CGPoint point1 = CGPointMake(-1, 5);
            CGPoint point2 = CGPointMake(10, 12);
            CGPoint sum = CGPointAdd(point1, point2);
            expect(sum).toEqual(CGPointMake(9, 17));
        });
    });

    describe(@"CGPointSubtract", ^{
        it(@"adds two points together, element-wise", ^{
            CGPoint point1 = CGPointMake(-1, 5);
            CGPoint point2 = CGPointMake(10, 12);
            CGPoint diff = CGPointSubtract(point1, point2);
            expect(diff).toEqual(CGPointMake(-11, -7));
        });
    });
});


SpecEnd
