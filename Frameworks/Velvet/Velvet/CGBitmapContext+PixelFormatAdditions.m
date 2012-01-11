//
//  CGBitmapContext+PixelFormatAdditions.m
//  Velvet
//
//  Created by James Lawton on 11/23/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/CGBitmapContext+PixelFormatAdditions.h>

CGContextRef CGBitmapContextCreateGeneric(CGSize size, BOOL hasAlpha) {
    size_t width = (size_t)ceil(size.width);

    CGImageAlphaInfo alphaInfo;
    if (hasAlpha)
        alphaInfo = kCGImageAlphaPremultipliedFirst;
    else
        alphaInfo = kCGImageAlphaNoneSkipFirst;

    // (A)RGB in host byte order (which is, incidentally, the only
    // pixel layout that correctly supports sub-pixel antialiasing text)
    CGBitmapInfo bitmapInfo = alphaInfo | kCGBitmapByteOrder32Host;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
        NULL,
        width,
        (size_t)ceil(size.height),
        8, // bits per component
        width * 4, // bytes per row
        colorSpace,
        bitmapInfo
    );

    CGColorSpaceRelease(colorSpace);
    return context;
}
