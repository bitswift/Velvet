//
//  NSColor+CoreGraphicsAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSColor+CoreGraphicsAdditions.h>
#import "EXTSafeCategory.h"

@safecategory (NSColor, CoreGraphicsAdditions)
+ (NSColor *)colorWithCGColor:(CGColorRef)color; {
    CGColorSpaceRef colorSpaceRef = CGColorGetColorSpace(color);
    NSColorSpace *colorSpace = [[NSColorSpace alloc] initWithCGColorSpace:colorSpaceRef];

    return [self colorWithColorSpace:colorSpace components:CGColorGetComponents(color) count:(size_t)CGColorGetNumberOfComponents(color)];
}

- (CGColorRef)CGColor; {
    NSInteger count = [self numberOfComponents];
    CGFloat components[count];
    [self getComponents:components];

    CGColorSpaceRef colorSpaceRef = self.colorSpace.CGColorSpace;
    return (__bridge CGColorRef)(__bridge_transfer __autoreleasing id)CGColorCreate(colorSpaceRef, components);
}

@end
