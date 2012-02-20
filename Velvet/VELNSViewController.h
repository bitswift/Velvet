//
//  VELNSViewController.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.02.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELViewController.h"
#import "VELNSView.h"

/**
 * A view controller with support for automatically setting up a <VELNSView>
 * with an `NSView` that has been loaded from a nib.
 */
@interface VELNSViewController : VELViewController

/**
 * @name Managing the View
 */

/**
 * The Velvet view managed and presented by this view controller.
 *
 * If no view has been set up when this property is read, <loadView> is invoked
 * to create one, and the new view is returned.
 */
@property (nonatomic, strong, readonly) VELNSView *view;

/**
 * The <[VELNSView guestView]> of the receiver's <view>.
 *
 * If no <view> has been set up when this property is read, <loadView> is
 * invoked to create one.
 */
@property (nonatomic, strong, readonly) IBOutlet NSView *guestView;

/**
 * Invoked to load the <view> for the first time.
 *
 * The default implementation of this method searches for <nibName> in
 * <nibBundle>. If a matching nib is found, it is loaded with the receiver as
 * the owner. If the <guestView> outlet is attached in the nib, it is loaded,
 * and a <VELNSView> is initialized with it and returned.
 *
 * If no nib can be found matching <nibName> in <nibBundle>, this method creates
 * a blank `NSView` with a frame of `CGRectZero`, and initializes and returns
 * a <VELNSView> with it.
 *
 * This method should never be explicitly called. It can be overridden by
 * subclasses to perform additional work upon view load.
 */
- (VELNSView *)loadView;

/**
 * @name Nib Loading
 */

/**
 * The name of the nib which should be loaded by <loadView>, or `nil` to not
 * load from a nib.
 *
 * The default implementation of this property returns `nil`.
 */
@property (nonatomic, copy, readonly) NSString *nibName;

/**
 * The bundle which should be searched for a nib to be loaded by <loadView>, or
 * `nil` to search in the main bundle.
 *
 * The default implementation of this property returns the bundle for the
 * receiver's class.
 */
@property (nonatomic, strong, readonly) NSBundle *nibBundle;

/**
 * Invoked after the receiver's <guestView> has been loaded from a nib.
 *
 * Overrides of this method should invoke the superclass implementation.
 */
- (void)awakeFromNib;

@end
