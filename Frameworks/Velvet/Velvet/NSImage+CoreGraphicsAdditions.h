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
 * The image returned will be scaled to the pixel density of the current
 * `NSGraphicsContext`. If there is no current `NSGraphicsContext`, the scale
 * factor of the first application window is used. If there are no application
 * windows, the pixel density is assumed to be one pixel per point, and no
 * scaling is done.
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
