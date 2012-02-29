//
//  NSScrollView+VELScrollViewAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.02.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSScrollView+VELScrollViewAdditions.h"
#import "EXTSafeCategory.h"
#import "NSClipView+VELScrollViewAdditions.h"
#import <objc/runtime.h>

@safecategory (NSScrollView, VELScrollViewAdditions)

#pragma mark Category initialization

+ (void)load {
    class_addProtocol([NSScrollView class], @protocol(VELScrollView));
}

#pragma mark VELScrollView

- (void)scrollToPoint:(CGPoint)point; {
    [self.contentView scrollToPoint:point];
}

- (void)scrollToIncludeRect:(CGRect)rect; {
    [self.contentView scrollToIncludeRect:rect];
}

@end
