//
//  NSView+VELNSViewAdditions.h
//  Velvet
//
//  Created by Josh Vera on 11/26/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>

@class VELNSView;

/*
 * Private extensions to `NSView` to support hosting by <VELNSView>.
 */
@interface NSView (VELNSViewAdditions)
/*
 * The <VELNSView> that is hosting this view, or `nil` if it exists
 * independently of a Velvet hierarchy.
 */
@property (unsafe_unretained) VELNSView *hostView;
@end
