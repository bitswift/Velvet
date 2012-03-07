//
//  VELClickEventRecognizer.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 04.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELEventRecognizer.h>

@protocol VELBridgedView;

/**
 * Recognizes one or more mouse clicks, which are mouse down events followed by
 * mouse up events.
 */
@interface VELClickEventRecognizer : VELEventRecognizer

/**
 * @name Configuring Recognition
 */

/**
 * The number of clicks (mouse down events followed by mouse up events) for the
 * event to be recognized.
 */
@property (nonatomic, assign) NSUInteger numberOfClicksRequired;

/**
 * @name Getting the Location of the Event
 */

/**
 * Returns the location of the first click in the coordinate system of the given
 * view.
 *
 * @param view The view with the coordinate system to use for the returned
 * point, or `nil` to return a point in the window's coordinate system. If not
 * `nil`, this view must be in the same window as the receiver's
 * <[VELEventRecognizer view]>.
 */
- (CGPoint)locationInView:(id<VELBridgedView>)view;

@end
