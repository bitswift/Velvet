//
//  VELNSViewLayer.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 23.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELViewLayer.h"
#import "VELNSView.h"

@class VELNSView;

/**
 * Private layer class for backing a <VELNSView>.
 */
@interface VELNSViewLayer : VELViewLayer

/**
 * @name View
 */

/**
 * The view that this layer is backing.
 */
@property (nonatomic, weak, readonly) VELNSView *view;

@end
