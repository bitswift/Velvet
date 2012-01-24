//
//  NSVelvetHostViewTests.m
//  Velvet
//
//  Created by Josh Vera on 1/3/12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSVelvetHostView.h"
#import "NSVelvetView.h"

SpecBegin(NSVelvetHostView)

describe(@"NSVelvetHostView", ^{
    it(@"has a hostView who's velvetView is the receiver.", ^{
        NSVelvetView *view = [[NSVelvetView alloc] init];
        NSVelvetHostView *hostView = [(id)view performSelector:@selector(velvetHostView)];

        expect(hostView.velvetView).toEqual(view);
    });
});

SpecEnd
