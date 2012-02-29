//
//  NSScrollView+VELScrollViewAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.02.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Velvet/VELScrollView.h>

/**
 * Implements <VELScrollView> for `NSScrollView`.
 *
 * Because the <VELScrollView> protocol is already implemented for `NSClipView`,
 * this category is simply a convenience that invokes the protocol methods
 * against the underlying `contentView`.
 */
@interface NSScrollView (VELScrollViewAdditions) <VELScrollView>
@end
