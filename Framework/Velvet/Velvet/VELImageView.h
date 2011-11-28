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
 * @name Image
 */

/**
 * The image to display in the receiver.
 */
@property CGImageRef image;

@end
