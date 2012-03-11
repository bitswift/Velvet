//
//  CGContext+CoreAnimationAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 11.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Draws the given layer tree into the given context.
 *
 * Drawing will occur in the coordinate space of the given layer (i.e.,
 * according to its `bounds`, not `frame`). Sublayers will be adjusted and
 * transformed appropriately.
 *
 * This will attempt to draw the layers in a manner that preserves vectors and
 * text, such that the rendering is suitable for a PDF or printing context.
 *
 * @param context The graphics context to draw into.
 * @param layer The root of the layer tree that should be drawn.
 *
 * @warning **Important:** This function may not support all features of the
 * Core Animation rendering and compositing model.
 */
void CGContextDrawCALayer (CGContextRef context, CALayer *layer);
