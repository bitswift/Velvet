//
//  VELView+VELViewProtected.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELView.h>

@protocol VELHostView;

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
 * Invoked any time an ancestor of the receiver has relaid itself out,
 * potentially moving or clipping the receiver relative to one of its ancestor
 * views.
 *
 * The default implementation forwards the message to all subviews.
 */
- (void)ancestorDidLayout;

/*
 * Invoked when the receiver's view hierarchy is being moved to a new host.
 *
 * This method is invoked on every view in the hierarchy. The default
 * implementation forwards the message to the receiver's subviews.
 *
 * @param hostView The view which will now host the receiver's hierarchy.
 */
- (void)willMoveToHostView:(id<VELHostView>)hostView;

/*
 * Invoked when the receiver's view hierarchy has moved to a new host.
 *
 * This method is invoked on every view in the hierarchy. The default
 * implementation forwards the message to the receiver's subviews.
 *
 * @param oldHostView The view which previously hosted the receiver's
 * hierarchy.
 */
- (void)didMoveFromHostView:(id<VELHostView>)oldHostView;

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
