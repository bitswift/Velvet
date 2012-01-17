//
//  NSViewAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 15.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSViewAdditionsTests.h"
#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

@interface NSViewAdditionsTests ()
@property (nonatomic, strong) VELWindow *window;
@end

@implementation NSViewAdditionsTests
@synthesize window = m_window;

- (void)setUp {
    self.window = [[VELWindow alloc] initWithContentRect:CGRectMake(100, 100, 500, 500)];
}

- (void)tearDown {
    self.window = nil;
}

- (void)testConformsToVELBridgedView {
    STAssertTrue([NSView conformsToProtocol:@protocol(VELBridgedView)], @"");

    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
    STAssertTrue([view conformsToProtocol:@protocol(VELBridgedView)], @"");
}

- (void)testConvertFromWindowPoint {
    NSView *view = [[NSView alloc] initWithFrame:CGRectMake(20, 50, 100, 200)];
    [self.window.contentView addSubview:view];

    CGPoint point = CGPointMake(125, 255);
    STAssertTrue(CGPointEqualToPoint([view convertFromWindowPoint:point], [view convertPoint:point fromView:nil]), @"");
}

- (void)testConvertToWindowPoint {
    NSView *view = [[NSView alloc] initWithFrame:CGRectMake(20, 50, 100, 200)];
    [self.window.contentView addSubview:view];

    CGPoint point = CGPointMake(125, 255);
    STAssertTrue(CGPointEqualToPoint([view convertToWindowPoint:point], [view convertPoint:point toView:nil]), @"");
}

- (void)testConvertFromWindowRect {
    NSView *view = [[NSView alloc] initWithFrame:CGRectMake(20, 50, 100, 200)];
    [self.window.contentView addSubview:view];

    CGRect rect = CGRectMake(30, 60, 145, 275);
    STAssertTrue(CGRectEqualToRect([view convertToWindowRect:rect], [view convertRect:rect toView:nil]), @"");
}

- (void)testConvertToWindowRect {
    NSView *view = [[NSView alloc] initWithFrame:CGRectMake(20, 50, 100, 200)];
    [self.window.contentView addSubview:view];

    CGRect rect = CGRectMake(30, 60, 145, 275);
    STAssertTrue(CGRectEqualToRect([view convertFromWindowRect:rect], [view convertRect:rect fromView:nil]), @"");
}

- (void)testLayer {
    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
    [view setWantsLayer:YES];

    STAssertNotNil(view.layer, @"");
}

- (void)testHostView {
    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];

    STAssertNil(view.hostView, @"");

    VELNSView *hostView = [[VELNSView alloc] init];
    view.hostView = hostView;

    STAssertEquals(view.hostView, hostView, @"");
}

- (void)testAncestorDidLayout {
    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
    STAssertNoThrow([view ancestorDidLayout], @"");
}

- (void)testAncestorNSVelvetView {
    NSVelvetView *velvetView = [[NSVelvetView alloc] initWithFrame:CGRectZero];

    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
    [velvetView addSubview:view];

    STAssertEquals(view.ancestorNSVelvetView, velvetView, @"");
}

- (void)testAncestorScrollView {
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
    STAssertEquals(scrollView.ancestorScrollView, scrollView, @"");

    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
    [scrollView setDocumentView:view];

    STAssertEquals(view.ancestorScrollView, scrollView, @"");
}

- (void)testWillMoveToNSVelvetView {
    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
    STAssertNoThrow([view willMoveToNSVelvetView:nil], @"");
}

- (void)testDidMoveFromNSVelvetView {
    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
    STAssertNoThrow([view didMoveFromNSVelvetView:nil], @"");
}

- (void)testDescendantViewAtPoint {
    NSView *superview = [[NSView alloc] initWithFrame:CGRectMake(20, 20, 80, 80)];

    NSView *subview = [[NSView alloc] initWithFrame:CGRectMake(50, 30, 100, 150)];
    [superview addSubview:subview];

    CGPoint subviewPoint = CGPointMake(51, 31);
    STAssertEquals([superview descendantViewAtPoint:subviewPoint], subview, @"");

    CGPoint superviewPoint = CGPointMake(49, 29);
    STAssertEquals([superview descendantViewAtPoint:superviewPoint], superview, @"");

    CGPoint outsidePoint = CGPointMake(49, 200);
    STAssertNil([superview descendantViewAtPoint:outsidePoint], @"");
}

- (void)testPointInside {
    NSView *view = [[NSView alloc] initWithFrame:CGRectMake(20, 20, 80, 80)];

    CGPoint insidePoint = CGPointMake(51, 31);
    STAssertTrue([view pointInside:insidePoint], @"");

    CGPoint outsidePoint = CGPointMake(49, 200);
    STAssertFalse([view pointInside:outsidePoint], @"");
}

@end
