//
//  NSVelvetView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Velvet/VELHostView.h>
#import <Velvet/VELView.h>

/**
 * A layer-backed `NSView` that is used to host a <VELView> hierarchy. Velvet
 * views must ultimately be rooted at an instance of this class in order to be
 * presented on-screen and respond to events.
 */
@interface NSVelvetView : NSView <VELHostView>

/**
 * @name View Hierarchy
 */

/**
 * The root view of a <VELView>-based hierarchy to be displayed in the receiver.
 * The value of this property is a plain <VELView> by default, but can be replaced
 * with another instance of <VELView> or any subclass.
 */
@property (nonatomic, strong) VELView *guestView;

/**
 * @name Drawing
 */

/**
 * Whether this view should be opaque.
 *
 * Setting this to `YES` can result in a significant speedup, but precludes
 * having any transparency in the view (and, by extension, its <guestView>). If
 * set to `YES`, the receiver's <guestView> must completely fill its bounds with
 * content.
 *
 * The default value is `NO`.
 */
@property (nonatomic, assign, getter = isOpaque) BOOL opaque;

@end
