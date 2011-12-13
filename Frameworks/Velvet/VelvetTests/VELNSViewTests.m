//
//  VELNSViewTests.m
//  Velvet
//
//  Created by James Lawton on 12/12/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELNSViewTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>


@implementation VELNSViewTests

- (void)testResponderChain {
    // Set up a VELNSView
    NSView *contained = [[NSView alloc] initWithFrame:CGRectZero];
    VELNSView *view = [[VELNSView alloc] initWithNSView:contained];

    // Set up a Velvet hierarchy
    NSVelvetView *host = [[NSVelvetView alloc] initWithFrame:CGRectZero];
    host.rootView.subviews = [NSArray arrayWithObject:view];

    // Check that the contained NSView's nextResponder is still the VELNSView, even
    // though its superview has been changed. Check that the VELNSView's nextResponder
    // is now set.
    STAssertEquals(host.rootView, [view nextResponder], @"");
    STAssertEquals(view, [contained nextResponder], @"");
}

@end
