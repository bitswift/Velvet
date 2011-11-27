//
//  VELViewPrivate.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Velvet/VELView.h>

@class VELContext;
@class NSVelvetView;

/*
 * Private functionality of <VELView> that needs to be exposed to other parts of
 * the framework.
 */
@interface VELView (VELViewPrivate)
@property (readwrite, weak) NSVelvetView *hostView;
@property (readwrite, strong) VELContext *context;

/*
 * How many levels deep in the hierarchy this view is.
 */
@property (readonly) NSUInteger viewDepth;
@end
