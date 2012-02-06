//
//  VELImageView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELView.h>

/**
 * An image view similar to `NSImageView` or `UIImageView`.
 */
@interface VELImageView : VELView

/**
 * @name Initialization
 */

/**
 * Initializes the receiver and sets its <image> property to the given image.
 *
 * The <[VELView bounds]> of the receiver will automatically be set to match the
 * the image dimensions.
 *
 * @param image The image to display in the receiver.
 */
- (id)initWithImage:(NSImage *)image;

/**
 * @name Image
 */

/**
 * The image to display in the receiver.
 */
@property (nonatomic, strong) NSImage *image;

/**
 * @name Scaling Behavior
 */

/**
 * Specifies the end caps of the receiver's <image>.
 *
 * During resizing, areas covered by a cap are not scaled or resized. The areas
 * not covered by a cap are scaled according to the receiver's <[VELView
 * contentMode]>.
 *
 * This is a convenience property which simply translates the receiver's
 * <[VELView contentStretch]> to and from the dimensions of the <image>.
 */
@property (nonatomic, assign) NSEdgeInsets endCapInsets;

@end
