//
//  CGBitmapContext+PixelFormatAdditions.h
//  Velvet
//
//  Created by James Lawton on 11/23/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * Returns a context suitable for rendering views.
 *
 * @param size The size, in pixels, to use for the created bitmap context.
 * @param hasAlpha Whether the context has an alpha channel.
 */
CGContextRef CGBitmapContextCreateGeneric(CGSize size, BOOL hasAlpha);
