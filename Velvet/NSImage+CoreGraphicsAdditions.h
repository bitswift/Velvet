//
//  NSImage+CoreGraphicsAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * Extensions to `NSImage` for interoperability with `CGImage`.
 */
@interface NSImage (CoreGraphicsAdditions)

/**
 * @name CGImage Conversion
 */

/**
 * The `CGImage` corresponding to the receiver.
 *
 * @note The image returned may not be scaled to the pixel density of the screen.
 */
@property (nonatomic, readonly) CGImageRef CGImage;

/**
 * Returns an `NSImage` corresponding to the given `CGImage`.
 *
 * @param image The `CGImage` to convert to an `NSImage`. The pixel dimensions
 * of the image are used as the size of the receiver.
 */
- (id)initWithCGImage:(CGImageRef)image;
@end
