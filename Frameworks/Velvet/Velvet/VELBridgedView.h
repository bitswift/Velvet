//
//  VELBridgedView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * Represents a view that can be bridged by Velvet, allowing interoperation with
 * other UI frameworks.
 */
@protocol VELBridgedView <NSObject>
@required

/**
 * Converts a point from the coordinate system of the window to that of the
 * receiver.
 *
 * @param point A point in the coordinate system of the receiver's window.
 */
- (CGPoint)convertFromWindowPoint:(CGPoint)point;

/**
 * Converts a point from the receiver's coordinate system to that of its window.
 *
 * @param point A point in the coordinate system of the receiver.
 */
- (CGPoint)convertToWindowPoint:(CGPoint)point;

/**
 * Converts a rectangle from the coordinate system of the window to that of the
 * receiver.
 *
 * @param rect A rectangle in the coordinate system of the receiver's window.
 */
- (CGRect)convertFromWindowRect:(CGRect)rect;

/**
 * Converts a rectangle from the receiver's coordinate system to that of its window.
 *
 * @param rect A rectangle in the coordinate system of the receiver.
 */
- (CGRect)convertToWindowRect:(CGRect)rect;

/**
 * Returns the <VELBridgedView> which is occupying the given point, or
 * `nil` if there is no such view.
 *
 * @param point A point, specified in the coordinate system of the receiver,
 * at which to look for a view.
 */
- (id<VELBridgedView>)descendantViewAtPoint:(CGPoint)point;

/**
 * Returns whether the receiver is occupying the given point.
 *
 * @param point A point, specified in the coordinate system of the receiver.
 */
- (BOOL)pointInside:(CGPoint)point;

@end
