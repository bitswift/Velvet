//
//  NSVelvetView+Private.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSVelvetView.h>

/*
 * Private functionality of <NSVelvetView> that needs to be exposed to other parts of
 * the framework.
 */
@interface NSVelvetView (Private)
/*
 * Whether user interaction (i.e., event handling) is enabled.
 *
 * This can be set to `NO` to effectively remove the `NSView` hierarchy from
 * consideration for events. Setting this property to `NO` does not affect event
 * handling for any Velvet views (since they are directly sent events from
 * <VELWindow>).
 *
 * The default value is `YES`.
 */
@property (nonatomic, assign, getter = isUserInteractionEnabled) BOOL userInteractionEnabled;
@end
