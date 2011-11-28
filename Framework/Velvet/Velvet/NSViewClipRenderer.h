//
//  NSViewClipRenderer.h
//  Velvet
//
//  Created by Josh Vera on 11/26/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VELNSView;

/*
 * A replacement delegate for the layer of an `NSView`. This will enable
 * clipping to the bounds of a <VELNSView> and forward on all delegate logic to
 * the original delegate of the `NSView`.
 */
@interface NSViewClipRenderer : NSObject

/*
 * @name Initialization
 */

/*
 * Initializes the receiver to manage the given layer, clipping it as
 * `clippedView` would be.
 *
 * This is the designated initializer.
 *
 * @param clippedView The view that would be clipped by a superview.
 * @param layer The layer to clip in order to match the view.
 */
- (id)initWithClippedView:(VELNSView *)clippedView layer:(CALayer *)layer;

/*
 * @name Rendering Hierarchies
 */

/*
 * The <VELNSView> whose bounds should be used to determine clipping on the
 * `NSView`.
 */
@property (nonatomic, weak, readonly) VELNSView *clippedView;

/*
 * The `CALayer` that this renderer is responsible for.
 */
@property (nonatomic, strong, readonly) CALayer *layer;

/*
 * The clip renderers used on the immediate sublayers of the receiver's layer.
 */
@property (nonatomic, strong, readonly) NSMutableArray *sublayerRenderers;

/*
 * @name Rendering
 */

/*
 * Tells the renderer to recalculate clipping regions for the <layer> and all
 * sublayers.
 */
- (void)clip;

@end
