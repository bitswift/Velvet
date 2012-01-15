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
 * Invoked any time an ancestor of the receiver has relaid itself out,
 * potentially moving or clipping the receiver relative to one of its ancestor
 * views.
 *
 * The default implementation forwards the message to all subviews.
 */
- (void)ancestorDidLayout;
@end
