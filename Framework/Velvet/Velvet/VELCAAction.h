//
//  VELCAAction.h
//  Velvet
//
//  Created by James Lawton on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/**
 * A CAAction which finds NSViews contained in Velvet and animated them alongside.
 * We pass through to the default animation to animate the Velvet views.
 */
@interface VELCAAction : NSObject <CAAction>

/**
 * Initializes an action which proxies for the given action, and handles animation
 * of descendent VELNSViews to the VELView whose layer it acts on.
 *
 * This is the designated initializer.
 */
- (id)initWithAction:(id <CAAction>)innerAction;

/**
 * Returns a caller-owned action, initialized with `initWithAction:`.
 */
+ (id)actionWithAction:(id <CAAction>)innerAction;

/**
 * Returns YES if objects of this class add features to actions for the given key.
 */
+ (BOOL)interceptsActionForKey:(NSString *)key;

@end
