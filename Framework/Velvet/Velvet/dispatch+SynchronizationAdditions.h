//
//  dispatch+SynchronizationAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Asynchronously starts trying to synchronize all of the provided queues,
 * executing `block` as soon as all of the queues have a barrier in place.
 */
void dispatch_multibarrier_async (dispatch_block_t block, dispatch_queue_t firstQueue, ...) NS_REQUIRES_NIL_TERMINATION;

/**
 * Synchronizes all of the provided queues and executes `block`.
 */
void dispatch_multibarrier_sync (dispatch_block_t block, dispatch_queue_t firstQueue, ...) NS_REQUIRES_NIL_TERMINATION;
