//
//  VELImageView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
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
- (id)initWithImage:(CGImageRef)image;

/**
 * @name Image
 */

/**
 * The image to display in the receiver.
 */
@property CGImageRef image;

@end
