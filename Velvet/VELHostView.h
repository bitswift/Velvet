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
 * A notification sent when <VELHostView> debug mode is enabled or disabled.
 *
 * In debug mode, host views are highlighted on screen using translucent colors,
 * with a different color assigned to each class implementing <VELHostView>.
 *
 * This notification will only be sent in Debug builds.
 */
extern NSString * const VELHostViewDebugModeChangedNotification;

/**
 * A user info key for `VELHostViewDebugModeChangedNotification`, associated
 * with a boolean `NSNumber` that indicates whether <VELHostView> debug mode is
 * now enabled or disabled.
 */
extern NSString * const VELHostViewDebugModeIsEnabledKey;

/**
 * Represents a view that can host views of other types (i.e., can bridge across
 * UI frameworks).
 *
 * Implementors of this protocol should respond to
 * `VELHostViewDebugModeChangedNotification` by applying a uniquely-colored
 * translucent overlay to their contents.
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
 * @note When this property is set, the given view's <[VELBridgedView hostView]>
 * property should automatically be set to the receiver.
 */
@property (nonatomic, strong) id<VELBridgedView> guestView;

@end
