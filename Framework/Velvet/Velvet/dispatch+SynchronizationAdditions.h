//
//  dispatch+SynchronizationAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Asynchronously synchronizes multiple queues and executes a block.
 *
 * @param block The block to execute when all of the queues are synchronized.
 * @param firstQueue The first dispatch queue to synchronize. This argument must
 * not be `NULL`.
 * @param ... The rest of the dispatch queues to synchronize, terminated with
 * `NULL`.
 */
void dispatch_multibarrier_async (dispatch_block_t block, dispatch_queue_t firstQueue, ...) NS_REQUIRES_NIL_TERMINATION;

/**
 * Synchronizes multiple queues and executes a block.
 *
 * @param block The block to execute when all of the queues are synchronized.
 * @param firstQueue The first dispatch queue to synchronize. This argument must
 * not be `NULL`.
 * @param ... The rest of the dispatch queues to synchronize, terminated with
 * `NULL`.
 */
void dispatch_multibarrier_sync (dispatch_block_t block, dispatch_queue_t firstQueue, ...) NS_REQUIRES_NIL_TERMINATION;

/**
 * Dispatches a block to a queue (which may be the current queue or `NULL`)
 * synchronously.
 *
 * @param queue The queue upon which to execute `block`. If this is the current
 * dispatch queue or `NULL`, the block is executed immediately on the current
 * thread.
 * @param block The block to execute synchronously.
 */
void dispatch_sync_recursive (dispatch_queue_t queue, dispatch_block_t block);
