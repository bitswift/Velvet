//
//  CALayer+GeometryAdditions.h
//  Velvet
//
//  Created by Josh Vera on 11/26/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (GeometryAdditions)
/**
 * Converts a rectangle from the receiver's coordinate system to that of a given
 * layer, taking into account any layer clipping between the two.
 *
 * This will traverse the layer hierarchy, finding a common ancestor between the
 * receiver and `layer` to use as a base for geometry conversion. If any layers
 * along the way (including the receiver, `layer`, and the common ancestor) have
 * `masksToBounds` set to `YES`, the rectangle takes into account their clipping
 * paths, such that the final result represents a rectangle that would actually
 * be visible on screen.
 *
 * @param rect A rectangle in the coordinate system of the receiver.
 * @param layer The layer whose coordinate system `rect` should be represented
 * in.
 *
 * @warning *Important:* The receiver and `layer` must have a common ancestor.
 */
- (CGRect)convertAndClipRect:(CGRect)rect toLayer:(CALayer *)layer;
@end
