//
//  VELViewPrivate.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Velvet/VELView.h>

@class NSVelvetView;
@class VELViewController;

/*
 * Private functionality of <VELView> that needs to be exposed to other parts of
 * the framework.
 */
@interface VELView (VELViewPrivate)
@property (nonatomic, readwrite, weak) NSVelvetView *hostView;

/*
 * A reference to the view controller which is managing the receiver.
 */
@property (nonatomic, weak) VELViewController *viewController;
@end
