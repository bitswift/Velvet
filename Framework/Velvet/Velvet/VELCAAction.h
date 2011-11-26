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
 * A `CAAction` which finds AppKit views contained in Velvet and animates them
 * alongside. We pass through to the default animation to animate the Velvet
 * views.
 */
@interface VELCAAction : NSObject <CAAction>

/**
 * @name Initialization
 */

/**
 * Initializes an action which proxies for the given action, and handles animation
 * of all descendent <VELNSView> instances along with the layer being acted upon.
 *
 * This is the designated initializer.
 *
 * @param innerAction The action to proxy. The receiver will call through to
 * this action to perform the original animation.
 */
- (id)initWithAction:(id <CAAction>)innerAction;

/**
 * Returns an action initialized with <initWithAction:>.
 *
 * @param innerAction The action to proxy. The receiver will call through to
 * this action to perform the original animation.
 */
+ (id)actionWithAction:(id <CAAction>)innerAction;

/**
 * @name Handling Actions
 */

/**
 * Returns `YES` if objects of this class add features to actions for the given
 * key.
 *
 * @param key The key for a layer property.
 */
+ (BOOL)interceptsActionForKey:(NSString *)key;

@end
