//
//  CGBitmapContext+PixelFormatAdditions.m
//  Velvet
//
//  Created by James Lawton on 11/23/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/CGBitmapContext+PixelFormatAdditions.h>

CGContextRef CGBitmapContextCreateGeneric(CGSize size) {
    size_t width = (size_t)ceil(size.width);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
        NULL,
        width,
        (size_t)ceil(size.height),
        8, // bits per component
        width * 4, // bytes per row
        colorSpace,
        // ARGB in host byte order (which is, incidentally, the only
        // CGBitmapInfo that correctly supports sub-pixel antialiasing text)
        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host
    );

    CGColorSpaceRelease(colorSpace);
    return context;
}
