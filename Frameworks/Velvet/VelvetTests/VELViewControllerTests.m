//
//  VELViewControllerTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 21.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELViewControllerTests.h"
#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

@interface TestViewController : VELViewController
@end

@implementation VELViewControllerTests

- (void)testInitialization {
    VELViewController *controller = [[VELViewController alloc] init];
    STAssertNotNil(controller, @"");
    STAssertFalse(controller.viewLoaded, @"");
}

- (void)testImplicitLoadView {
    VELViewController *controller = [[VELViewController alloc] init];
    
    // using the 'view' property should load it into memory
    VELView *view = controller.view;

    STAssertNotNil(view, @"");
    STAssertTrue(controller.viewLoaded, @"");

    // re-reading the property should return the same view
    STAssertEqualObjects(controller.view, view, @"");
}

- (void)testLoadView {
    VELViewController *controller = [[VELViewController alloc] init];

    VELView *view = [controller loadView];
    STAssertNotNil(view, @"");
    
    // the view should have zero width and zero height
    STAssertTrue(CGRectEqualToRect(view.bounds, CGRectZero), @"");
}

@end

@implementation TestViewController
@end
