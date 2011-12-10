//
//  NSView+ScrollViewAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * Additions to support interchangeable scrolling logic between Velvet and
 * AppKit.
 */
@interface NSView (ScrollViewAdditions)
/**
 * Returns the closest ancestor scroll view containing the receiver, or `nil` if
 * there is no such view.
 *
 * This may return an `NSScrollView`, a <VELScrollView>, or a custom class. This
 * method will search both Velvet and AppKit hierarchies.
 */
- (id)ancestorScrollView;
@end
