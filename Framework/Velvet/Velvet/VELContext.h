//
//  VELContext.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Manages the state and resources for an entire Velvet view hierarchy and
 * rendering context.
 *
 * Each `VELNSView` implicitly creates a `VELContext`, which it owns, and uses
 * it to render its hosted view hierarchy.
 */
@interface VELContext : NSObject
/**
 * A serial dispatch queue that can be used to enforce an order for operations
 * performed with regard to the receiver.
 */
@property (nonatomic, readonly) dispatch_queue_t dispatchQueue;

/**
 * The `VELContext` being used on the current thread, or `nil` if the current
 * thread has no context set up.
 */
+ (VELContext *)currentContext;

/**
 * Adds `context` to the current thread's stack, making it the current context.
 * When you are finished using it as the current context, you should invoke
 * `popCurrentContext`.
 */
+ (void)pushCurrentContext:(VELContext *)context;

/**
 * Matches a previous call to `pushCurrentContext:`, restoring the current
 * context to what it was previously.
 *
 * @warning Calls to this method must exactly match the number of previous calls
 * to `pushCurrentContext:` on the current thread.
 */
+ (void)popCurrentContext;
@end
