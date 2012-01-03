//
//  NSVelvetHostViewTests.m
//  Velvet
//
//  Created by Josh Vera on 1/3/12.
//  Copyright (c) 2012 Emerald Lark. All rights reserved.
//

#import "NSVelvetHostViewTests.h"

#import <Cocoa/Cocoa.h>
#import "NSVelvetHostView.h"
#import "NSVelvetView.h"

@implementation NSVelvetHostViewTests

- (void)testVelvetViewProperty {
    NSVelvetView *view = [[NSVelvetView alloc] init];
    NSVelvetHostView *hostView = [(id)view performSelector:@selector(velvetHostView)];
    STAssertEqualObjects(hostView.velvetView, view, @"");
}

@end
