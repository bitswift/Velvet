//
//  CATransaction+BlockAdditions.m
//  Velvet
//
//  Created by James Lawton on 11/23/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "CATransaction+BlockAdditions.h"
#import "EXTSafeCategory.h"

@safecategory (CATransaction, BlockAdditions)
+ (void)performWithDisabledActions:(void(^)(void))block {
    if ([self disableActions]) {
        // actions are already disabled
        block();
    } else {
        [self setDisableActions:YES];
        block();
        [self setDisableActions:NO];
    }
}

@end
