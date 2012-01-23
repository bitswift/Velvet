//
//  VELViewLayer.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 14.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class VELView;

/**
 * Private layer class for backing a <VELView>.
 */
@interface VELViewLayer : CALayer

/**
 * @name View
 */

/**
 * The view that this layer is backing.
 */
@property (nonatomic, weak, readonly) VELView *view;
@end
