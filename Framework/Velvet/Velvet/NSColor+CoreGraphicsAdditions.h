//
//  NSColor+CoreGraphicsAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * Extensions to `NSColor` for interoperability with `CGColor`.
 */
@interface NSColor (CoreGraphicsAdditions)

/**
 * @name CGColor Conversion
 */

/**
 * The `CGColor` corresponding to the receiver.
 */
@property (nonatomic, readonly) CGColorRef CGColor;

/**
 * Returns an `NSColor` corresponding to the given `CGColor`.
 *
 * @param color The `CGColor` to convert to an `NSColor`.
 */
+ (NSColor *)colorWithCGColor:(CGColorRef)color;
@end
