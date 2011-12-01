//
//  VELScrollView.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>

/**
 * A scrollable view similar to `NSScrollView` or `UIScrollView`.
 *
 * To add views to the scrollable area, add them as subviews of the scroll view.
 */
@interface VELScrollView : VELView

/**
 * @name Content
 */

/**
 * The size, in points, of the scrollable content.
 *
 * This defaults to `CGSizeZero`.
 */
@property (nonatomic, assign) CGSize contentSize;

/**
 * @name Scrollers
 */

/**
 * The horizontal scroller displayed in the scroll view.
 */
@property (nonatomic, strong, readonly) NSScroller *horizontalScroller;

/**
 * The vertical scroller displayed in the scroll view.
 */
@property (nonatomic, strong, readonly) NSScroller *verticalScroller;
@end
