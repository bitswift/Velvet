//
//  CATransaction+BlockAdditions.h
//  Velvet
//
//  Created by James Lawton on 11/23/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CATransaction (BlockAdditions)

/**
 * Perform the given block in a transaction with disabled
 * actions.
 *
 * This will have the effect of suppressing animation.
 */
+ (void)performWithDisabledActions:(void(^)(void))block;

@end
