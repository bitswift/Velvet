//
//  NSColor+CoreGraphicsAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSColor+CoreGraphicsAdditions.h>
#import <Velvet/NSImage+CoreGraphicsAdditions.h>
#import "EXTSafeCategory.h"

static void drawCGImagePattern (void *info, CGContextRef context) {
    CGImageRef image = info;

    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
}

static void releasePatternInfo (void *info) {
    CFRelease(info);
}

@safecategory (NSColor, CoreGraphicsAdditions)
+ (NSColor *)colorWithCGColor:(CGColorRef)color; {
    CGColorSpaceRef colorSpaceRef = CGColorGetColorSpace(color);

    NSColorSpace *colorSpace = [[NSColorSpace alloc] initWithCGColorSpace:colorSpaceRef];
    NSColor *result = [self colorWithColorSpace:colorSpace components:CGColorGetComponents(color) count:(size_t)CGColorGetNumberOfComponents(color)];
    [colorSpace release];

    return result;
}

- (CGColorRef)CGColor; {
    if ([[self colorSpaceName] isEqualToString:NSPatternColorSpace]) {
        CGImageRef patternImage = [self patternImage].CGImage;
        if (!patternImage)
            return NULL;

        // bridge a bit to trick Clang into not complaining about the unbalanced
        // retain below -- the image gets released in releasePatternInfo()
        id patternObj = (__bridge id)patternImage;

        size_t width = CGImageGetWidth(patternImage);
        size_t height = CGImageGetHeight(patternImage);

        CGRect patternBounds = CGRectMake(0, 0, width, height);
        CGPatternRef pattern = CGPatternCreate(
            (__bridge_retained void *)patternObj,
            patternBounds,
            CGAffineTransformIdentity,
            width,
            height,
            kCGPatternTilingConstantSpacingMinimalDistortion,
            YES,
            &(CGPatternCallbacks){
                .version = 0,
                .drawPattern = &drawCGImagePattern,
                .releaseInfo = &releasePatternInfo
            }
        );

        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreatePattern(NULL);

        CGColorRef result = CGColorCreateWithPattern(colorSpaceRef, pattern, (CGFloat[]){ 1.0 });

        CGColorSpaceRelease(colorSpaceRef);
        CGPatternRelease(pattern);

        return (CGColorRef)[(id)result autorelease];
    } else {
        NSInteger count = [self numberOfComponents];
        CGFloat components[count];
        [self getComponents:components];

        CGColorSpaceRef colorSpaceRef = self.colorSpace.CGColorSpace;
        CGColorRef result = CGColorCreate(colorSpaceRef, components);

        return (CGColorRef)[(id)result autorelease];
    }
}

@end
