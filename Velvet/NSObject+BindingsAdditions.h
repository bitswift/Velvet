//
//  NSObject+BindingsAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Generic extensions to bindings.
 */
@interface NSObject (BindingsAdditions)

/**
 * @name Editor Registration
 */

/**
 * Registers the receiver for editing with every object it is bound to.
 *
 * This will invoke `objectDidBeginEditing:` on the observed object of each of
 * the receiver's bindings.
 */
- (void)notifyBoundObjectsOfDidBeginEditing;

/**
 * Unregisters the receiver from editing with every object it is bound to.
 *
 * This will invoke `objectDidEndEditing:` on the observed object of each of the
 * receiver's bindings.
 */
- (void)notifyBoundObjectsOfDidEndEditing;

@end
