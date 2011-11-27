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
 * The <VELNSView> whose bounds should be used to determine clipping on the
 * `NSView`.
 */
@property (nonatomic, weak) VELNSView *clippedView;

/*
 * The original delegate for the layer of the `NSView` that should be clipped.
 *
 * The receiver will forward delegate messages to this object once it has
 * performed the necessary setup.
 */
@property (nonatomic, weak) id originalLayerDelegate;
@end
