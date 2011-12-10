//
//  CATransaction+BlockAdditions.m
//  Velvet
//
//  Created by James Lawton on 11/23/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/CATransaction+BlockAdditions.h>
#import <Proton/EXTSafeCategory.h>

@safecategory (CATransaction, BlockAdditions)
+ (void)performWithDisabledActions:(void(^)(void))block {
    if ([self disableActions]) {
        // actions are already disabled
        block();
    } else {
        [self begin];
        [self setDisableActions:YES];
        block();
        [self commit];
    }
}

@end
