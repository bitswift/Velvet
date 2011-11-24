//
//  CATransaction+BlockAdditions.m
//  Velvet
//
//  Created by James Lawton on 11/23/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/CATransaction+BlockAdditions.h>

@implementation CATransaction (BlockAdditions)

+ (void)performWithDisabledActions:(void(^)(void))block {
    [self begin];
    [self setDisableActions:YES];
    block();
    [self commit];
}

@end
