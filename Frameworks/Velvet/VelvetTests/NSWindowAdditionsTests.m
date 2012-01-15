//
//  NSWindowAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 15.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSWindowAdditionsTests.h"
#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

@implementation NSWindowAdditionsTests

- (void)testInitializationWithContentRect {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 500)];
    STAssertNotNil(window, @"");

    CGRect contentRect = [window contentRectForFrameRect:window.frame];
    STAssertTrue(CGSizeEqualToSize(contentRect.size, CGSizeMake(500, 500)), @"");
}

- (void)testInitializationWithContentRectAndStyle {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 500) styleMask:NSBorderlessWindowMask];
    STAssertNotNil(window, @"");

    CGRect contentRect = [window contentRectForFrameRect:window.frame];
    STAssertTrue(CGSizeEqualToSize(contentRect.size, CGSizeMake(500, 500)), @"");
}

@end
