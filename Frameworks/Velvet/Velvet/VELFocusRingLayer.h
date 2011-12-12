//
//  VELFocusRingLayer.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class VELView;

/*
 * A layer representing a standard focus ring around an `NSView`.
 *
 * This layer does not actually know how to draw a focus ring. Instead, it must
 * be provided the original focus ring layer (which has to be found manually in
 * the layer tree), which it will then clip and render in the appropriate
 * location.
 */
@interface VELFocusRingLayer : CALayer

/*
 * @name Initialization
 */

/*
 * Initializes the receiver with an existing focus ring layer.
 *
 * This is the designated initializer for this class.
 *
 * @param layer A layer provided by AppKit for the purpose of drawing a focus
 * ring. This layer will be hidden when the receiver begins rendering.
 * @param hostView The <VELView> which has focus.
 */
- (id)initWithOriginalLayer:(CALayer *)layer hostView:(VELView *)hostView;

/*
 * @name Original Layer
 */

/*
 * The original focus ring layer, as provided to
 * <initWithOriginalLayer:hostView:>.
 */
@property (nonatomic, weak, readonly) CALayer *originalLayer;

@end
