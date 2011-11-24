//
//  VELContext.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELContext.h>

@interface VELContext ()
/**
 * Returns a mutable array representing the context stack for the current
 * thread, creating one if it does not already exist.
 */
+ (NSMutableArray *)currentThreadContextStack;
@end

@implementation VELContext

#pragma mark Properties

@synthesize dispatchQueue = m_dispatchQueue;

#pragma mark Context stack

+ (NSMutableArray *)currentThreadContextStack; {
    static NSString * const contextStackKey = @"VELContextStack";

    NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];

    NSMutableArray *contextStack = [threadDict objectForKey:contextStackKey];
    if (!contextStack) {
        contextStack = [[NSMutableArray alloc] init];
        [threadDict setObject:contextStack forKey:contextStackKey];
    }

    return contextStack;
}

+ (VELContext *)currentContext; {
    NSArray *contextStack = [self currentThreadContextStack];
    if (![contextStack count])
        return nil;

    return [contextStack lastObject];
}

+ (void)pushCurrentContext:(VELContext *)context; {
    [[self currentThreadContextStack] addObject:context];
}

+ (void)popCurrentContext; {
    [[self currentThreadContextStack] removeLastObject];
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_dispatchQueue = dispatch_queue_create("com.emeraldlark.Velvet.VELContext.dispatchQueue", DISPATCH_QUEUE_SERIAL);
    return self;
}

- (void)dealloc {
    dispatch_barrier_sync(m_dispatchQueue, ^{});
    dispatch_release(m_dispatchQueue);
    m_dispatchQueue = NULL;
}

@end
