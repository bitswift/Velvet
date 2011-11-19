//
//  VELView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELResponder.h>

/**
 * A layer-backed view. A view hierarchy built using this class must ultimately
 * be hosted in a `VELNSView`.
 */
@interface VELView : VELResponder
/**
 * The frame of this view, in its superview's coordinate system.
 */
@property (assign) CGRect frame;

/**
 * The layer backing this view. This will be an instance of the `layerClass`
 * specified by the receiver's class.
 */
@property (readonly, strong) CALayer *layer;

/**
 * The class of Core Animation layer to use for this view's backing store.
 */
+ (Class)layerClass;

/**
 * Initializes the receiver.
 *
 * In contrast to `NSView` or `UIView`, this is the designated initializer for
 * this class, because the frame that a view is initialized with often says very
 * little about its final frame or layout, and implies that callers should
 * attempt to provide meaningful values. Instead of worrying about geometry at
 * the time of initialization, the #frame can be set as soon as it is actually
 * appropriate.
 */
- (id)init;

/**
 * Can be overridden to perform custom drawing.
 *
 * The default implementation of this method does nothing.
 */
- (void)drawRect:(CGRect)rect;
@end
