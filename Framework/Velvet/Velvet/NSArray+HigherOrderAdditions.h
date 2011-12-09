//
//  NSArray+HigherOrderAdditions.h
//  Velvet
//
//  Created by Josh Vera on 12/7/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Higher order extensions to NSArray.
 */
@interface NSArray (HigherOrderAdditions)

/**
 * Returns an array of filtered objects for which `block` returns true.
 *
 * @param block A predicate block that accepts an `obj`, an `index` and returns a predicate.
 */
- (NSArray *)filterUsingBlock:(BOOL(^)(id obj))block;

/**
 * Returns an array of filtered objects for which `block` returns true, applying `opts` while filtering.
 *
 * @param opts A mask of `NSEnumerationOptions` to apply when filtering.
 * @param block A predicate block that accepts an `obj`, an `index` and returns a predicate.
 */
- (NSArray *)filterWithOptions:(NSEnumerationOptions)opts usingBlock:(BOOL(^)(id obj))block;
@end
