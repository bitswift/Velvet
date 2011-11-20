//
//  dispatch+SynchronizationAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/dispatch+SynchronizationAdditions.h>

/**
 * A generic comparison function for sorting dispatch queues into a known order.
 */
static int compareDispatchQueues (const void *a, const void *b) {
	if (a > b)
		return 1;
	else if (a < b)
		return -1;
	else
		return 0;
}

/**
 * Synchronizes all of the provided queues and executes `block`. If
 * `asynchronous` is `YES`, the function returns immediately, and `block` is
 * asynchronously executed once all the queues have been joined.
 */
static void dispatch_multibarrier_array (BOOL asynchronous, const dispatch_queue_t *originalQueues, size_t queueCount, dispatch_block_t block);

void dispatch_async_recursive (dispatch_queue_t queue, dispatch_block_t block) {
	if (!queue || dispatch_get_current_queue() == queue)
		block();
	else
		dispatch_async(queue, block);
}

void dispatch_multibarrier_async (dispatch_block_t block, dispatch_queue_t firstQueue, ...) {
	NSCParameterAssert(block != NULL);
	NSCParameterAssert(firstQueue != NULL);

	va_list args;
	va_start(args, firstQueue);

	size_t queueCount = 1;
	for (;;) {
		dispatch_queue_t nextQueue = va_arg(args, dispatch_queue_t);
		if (!nextQueue)
			break;

		++queueCount;
	}

	va_end(args);

	dispatch_queue_t queues[queueCount];
	queues[0] = firstQueue;

	va_start(args, firstQueue);
	for (size_t i = 1;i < queueCount;++i) {
		dispatch_queue_t nextQueue = va_arg(args, dispatch_queue_t);
		queues[i] = nextQueue;
	}

	va_end(args);

	dispatch_multibarrier_array(YES, queues, queueCount, block);
}

void dispatch_multibarrier_sync (dispatch_block_t block, dispatch_queue_t firstQueue, ...) {
	NSCParameterAssert(block != NULL);
	NSCParameterAssert(firstQueue != NULL);

	va_list args;
	va_start(args, firstQueue);

	size_t queueCount = 1;
	for (;;) {
		dispatch_queue_t nextQueue = va_arg(args, dispatch_queue_t);
		if (!nextQueue)
			break;

		++queueCount;
	}

	va_end(args);

	dispatch_queue_t queues[queueCount];
	queues[0] = firstQueue;

	va_start(args, firstQueue);
	for (size_t i = 1;i < queueCount;++i) {
		dispatch_queue_t nextQueue = va_arg(args, dispatch_queue_t);
		queues[i] = nextQueue;
	}

	va_end(args);

	dispatch_multibarrier_array(NO, queues, queueCount, block);
}

void dispatch_sync_recursive (dispatch_queue_t queue, dispatch_block_t block) {
	if (!queue || dispatch_get_current_queue() == queue)
		block();
	else
		dispatch_sync(queue, block);
}

static void dispatch_multibarrier_array (BOOL asynchronous, const dispatch_queue_t *originalQueues, size_t queueCount, dispatch_block_t block) {
	NSCParameterAssert(originalQueues != NULL);
	NSCParameterAssert(queueCount > 0);
	NSCParameterAssert(block != NULL);

	dispatch_queue_t *queues = malloc(sizeof(*originalQueues) * queueCount);
	for (size_t i = 0;i < queueCount;++i) {
		queues[i] = originalQueues[i];

		// don't retain the first queue, since we'll be jumping to it (and
		// implicitly retaining it) immediately
		if (i != 0) {
			dispatch_retain(queues[i]);
		}
	}

	// put the queues into a known order to avoid deadlocks
	qsort(queues, queueCount, sizeof(*queues), &compareDispatchQueues);

	__block __unsafe_unretained dispatch_block_t weakJumpingBlock;
	__block size_t queueIndex = 0;

	dispatch_block_t jumpingBlock = ^{
		if (queueIndex == queueCount - 1) {
			block();
		} else {
			++queueIndex;

			dispatch_barrier_sync(queues[queueIndex], weakJumpingBlock);

			// balance the retain we performed when setting up the 'queues'
			// array
			dispatch_release(queues[queueIndex]);
			
			--queueIndex;
		}
	};

	jumpingBlock = [jumpingBlock copy];
	weakJumpingBlock = jumpingBlock;

	dispatch_queue_t rootQueue = queues[0];
	dispatch_block_t rootBlock = ^{
		jumpingBlock();
		free(queues);
	};

	if (asynchronous)
		dispatch_barrier_async(rootQueue, rootBlock);
	else
		dispatch_barrier_sync(rootQueue, rootBlock);
}
