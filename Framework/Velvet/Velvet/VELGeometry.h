//
//  VELGeometry.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * Represents an object that can convert geometry to and from its window
 * coordinates.
 *
 * This must be implemented by any view class that wishes to be compatible with
 * the geometry methods of `VELView`.
 */
@protocol VELGeometry <NSObject>
@required
/**
 * Converts `point` from the coordinate system of the receiver's window to that
 * of the receiver.
 */
- (CGPoint)convertFromWindowPoint:(CGPoint)point;

/**
 * Converts `point` from the receiver's coordinate system to that of its window.
 */
- (CGPoint)convertToWindowPoint:(CGPoint)point; 

/**
 * Converts `rect` from the coordinate system of the receiver's window to that
 * of the receiver.
 */
- (CGRect)convertFromWindowRect:(CGRect)rect;

/**
 * Converts `rect` from the receiver's coordinate system to that of its window.
 */
- (CGRect)convertToWindowRect:(CGRect)rect;
@end
