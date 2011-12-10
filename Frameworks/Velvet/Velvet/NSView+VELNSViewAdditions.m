//
//  NSView+VELNSViewAdditions.m
//  Velvet
//
//  Created by Josh Vera on 11/26/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSView+VELNSViewAdditions.h>
#import <Velvet/VELNSView.h>
#import <objc/runtime.h>
#import "EXTSafeCategory.h"

@safecategory (NSView, VELNSViewAdditions)

#pragma mark Properties

- (VELNSView *)hostView {
    return objc_getAssociatedObject(self, @selector(hostView));
}

- (void)setHostView:(VELNSView *)hostView {
    objc_setAssociatedObject(self, @selector(hostView), hostView, OBJC_ASSOCIATION_ASSIGN);
}

@end
