//
//  VELView+VELViewProtected.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>

@class NSVelvetView;

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

/*
 * Invoked any time an ancestor of the receiver has scrolled, potentially moving
 * or clipping the receiver.
 *
 * The default implementation forwards the message to all subviews.
 */
- (void)ancestorDidScroll;

/*
 * Invoked when the receiver's view hierarchy is being moved to a new host.
 *
 * This method is invoked on every view in the hierarchy. The default
 * implementation forwards the message to the receiver's subviews.
 *
 * @param hostView The view which will now host the receiver's hierarchy.
 */
- (void)willMoveToHostView:(NSVelvetView *)hostView;

/*
 * Invoked when the receiver's view hierarchy has moved to a new host.
 *
 * This method is invoked on every view in the hierarchy. The default
 * implementation forwards the message to the receiver's subviews.
 */
- (void)didMoveToHostView;

/*
 * Runs a block to change properties on one or more layers, taking into account
 * whether <VELView> animations are currently enabled.
 * 
 * If this is run from inside an animation block, the changes are animated as
 * part of the animation. Otherwise, the changes take effect immediately,
 * without animation.
 *
 * @param changesBlock A block containing changes to make to layers.
 */
+ (void)changeLayerProperties:(void (^)(void))changesBlock;
@end
