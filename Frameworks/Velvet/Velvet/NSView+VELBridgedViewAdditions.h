//
//  NSView+VELBridgedViewAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Velvet/VELBridgedView.h>
#import <Velvet/VELHostView.h>

@class VELNSView;

/**
 * Implements <VELBridgedView> for `NSView`.
 */
@interface NSView (VELBridgedViewAdditions) <VELBridgedView>

/**
 * @name View Hierarchy
 */

/**
 * The <VELNSView> that is hosting this view, or `nil` if it exists
 * independently of a Velvet hierarchy.
 */
@property (nonatomic, unsafe_unretained) VELNSView<VELHostView> *hostView;
@end
