//
//  NSArray+HigherOrderAdditions.m
//  Velvet
//
//  Created by Josh Vera on 12/7/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSArray+HigherOrderAdditions.h>

@implementation NSArray (HigherOrderAdditions)

- (NSArray *)filterUsingBlock:(BOOL(^)(id obj))block {
    return [self filterWithOptions:0 usingBlock:block];
}

- (NSArray *)filterWithOptions:(NSEnumerationOptions)opts usingBlock:(BOOL(^)(id obj))block {
    return [self objectsAtIndexes:
        [self indexesOfObjectsWithOptions:opts passingTest:^(id obj, NSUInteger idx, BOOL *stop) {
            return block(obj);
        }]
    ];
}
@end
