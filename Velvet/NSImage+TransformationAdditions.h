//
//  NSImage+TransformationAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Extensions to `NSImage` that support transformations of the image data.
 */
@interface NSImage (TransformationAdditions)

/**
 * @name Density Adjustments
 */

/**
 * Returns a copy of the receiver with a size equal to the pixel dimensions of
 * the largest representation, multiplied by the given scale.
 *
 * In other words, this adjusts the density of the image, such that one point
 * equals `scale` pixels.
 *
 * @param scale The new scale value for the image.
 */
- (NSImage *)imageWithScale:(CGFloat)scale;

@end
