//
//  VELViewPrivate.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Velvet/VELView.h>

@class VELViewController;

/**
 * Private functionality of <VELView> that needs to be exposed to other parts of
 * the framework.
 */
@interface VELView (VELViewPrivate)
/**
 * A reference to the view controller which is managing the receiver.
 */
@property (nonatomic, weak) VELViewController *viewController;

/**
 * Whether this view class does its own drawing, as determined by the
 * implementation of a <drawRect:> method.
 *
 * If this is `YES`, a bitmap context is automatically created for drawing, and
 * the results of any drawing are cached in its layer.
 */
+ (BOOL)doesCustomDrawing;
@end
