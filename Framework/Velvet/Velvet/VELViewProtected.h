//
//  VELView+VELViewProtected.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>

/*
 * Protected functionality of <VELView> exposed for subclasses.
 *
 * These methods should not be called from outside the class hierarchy.
 */
@interface VELView (VELViewProtected)
/*
 * Invoked when a new subview is being added and its layer needs to be added to
 * the tree.
 *
 * The default implementation adds the layer of `view` to the receiver's layer.
 * This can be overridden to add a sublayer somewhere else, or avoid displaying
 * it at all.
 *
 * @param view The view being added as a subview.
 */
- (void)addSubviewToLayer:(VELView *)view;
@end
