//
//  VELDragEventRecognizer.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 06.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELEventRecognizer.h>

/**
 * Recognizes a mouse dragging event.
 */
@interface VELDragEventRecognizer : VELEventRecognizer

/**
 * @name Configuring Recognition
 */

/**
 * The minimum distance, in points, that the mouse must have moved (while held
 * down) in order for the drag to begin.
 *
 * The default value for this property is zero.
 */
@property (nonatomic, assign) CGFloat minimumDistance;

/**
 * Whether translation should be locked to 45° axes when the shift key is held down
 * during a drag.
 *
 * If this is set to `YES` and shift is being held down, the
 * <translationInView:> method will only return values that have been projected
 * to one of the axes. Otherwise, the values returned by <translationInView:>
 * describe the exact cursor position without modification.
 *
 * The default value for this property is `YES`.
 */
@property (nonatomic, assign) BOOL shiftLocksAxes;

/**
 * @name Location Tracking
 */

/**
 * The most recent location of the cursor in the coordinate system of the given
 * view.
 *
 * <shiftLocksAxes> has no effect on the return value of this method.
 *
 * @param view The view with the coordinate system to use for the returned
 * point, or `nil` to return a point in the window's coordinate system. If not
 * `nil`, this view must be in the same window as the receiver's
 * <[VELEventRecognizer view]>.
 */
- (CGPoint)locationInView:(id<VELBridgedView>)view;

/**
 * The total translation of the cursor since the drag began, in the coordinate
 * system of the given view.
 *
 * The returned point may not actually match the true cursor translation if
 * <shiftLocksAxes> is enabled.
 *
 * @param view The view with the coordinate system to use for the translation,
 * or `nil` to return the translation in the window's coordinate system. If not
 * `nil`, this view must be in the same window as the receiver's
 * <[VELEventRecognizer view]>.
 */
- (CGPoint)translationInView:(id<VELBridgedView>)view;

@end
