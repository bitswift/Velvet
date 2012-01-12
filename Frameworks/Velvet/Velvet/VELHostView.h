//
//  VELHostView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 12.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Velvet/VELBridgedView.h>

/**
 * Represents a view that can host views of other types (i.e., can bridge across
 * UI frameworks).
 */
@protocol VELHostView <VELBridgedView>
@required

/**
 * @name Guest View
 */

/**
 * The view hosted by the receiver.
 *
 * Implementing classes may require that this property be of a more specific
 * type.
 *
 * @warning **Important:** When this property is set, the given view's
 * <[VELBridgedView hostView]> property should automatically be set to the
 * receiver.
 */
@property (nonatomic, strong) id<VELBridgedView> guestView;
@end
