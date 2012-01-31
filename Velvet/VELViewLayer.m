//
//  VELViewLayer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 14.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELViewLayer.h"
#import "VELView.h"
#import "VELViewPrivate.h"
#import "CATransaction+BlockAdditions.h"

@interface VELViewLayer ()
/**
 * How many fractions of a point belong in the X coordinate of the receiver's
 * `position`, but have been rounded off to keep the receiver on whole points.
 */
@property (nonatomic, assign) CGFloat roundoffErrorX;

/**
 * How many fractions of a point belong in the Y coordinate of the receiver's
 * `position`, but have been rounded off to keep the receiver on whole points.
 */
@property (nonatomic, assign) CGFloat roundoffErrorY;
@end

@implementation VELViewLayer

#pragma mark Properties

@synthesize roundoffErrorX = m_roundoffErrorX;
@synthesize roundoffErrorY = m_roundoffErrorY;

- (VELView *)view {
    VELView *view = self.delegate;
    NSAssert(!view || [view isKindOfClass:[VELView class]], @"Delegate of %@ is not a VELView: %@", self, view);

    return view;
}

#pragma mark Drawing

- (void)display {
    if (![[self.view class] doesCustomDrawing])
        return;

    [CATransaction performWithDisabledActions:^{
        [super display];
    }];
}

#pragma mark Autoresizing

- (void)resizeSublayersWithOldSize:(CGSize)size {
    for (CALayer *layer in self.sublayers) {
        [layer resizeWithOldSuperlayerSize:size];
    }
}

- (void)resizeWithOldSuperlayerSize:(CGSize)oldSize {
    unsigned autoresizingMask = self.autoresizingMask;
    if (!autoresizingMask) {
        return;
    }

    CGSize newSize = self.superlayer.bounds.size;

    CGFloat deltaX = newSize.width - oldSize.width;
    CGFloat deltaY = newSize.height - oldSize.height;

    CGRect frame = CGRectOffset(self.frame, self.roundoffErrorX, self.roundoffErrorY);

    if (autoresizingMask & kCALayerWidthSizable) {
        frame.size.width += deltaX;
    }

    if (autoresizingMask & kCALayerHeightSizable) {
        frame.size.height += deltaY;
    }

    /*
     * Here's where we begin to differ from the vanilla AppKit/CoreAnimation
     * implementation. AppKit will always attempt to land the frame on whole
     * points, but it does so by rounding up the size if necessary. Instead, we
     * accept fractional points, and only floor (we don't ever round up) if the
     * VELView we're backing says that we should.
     */
    if (autoresizingMask & kCALayerMinXMargin) {
        if (autoresizingMask & kCALayerMaxXMargin) {
            frame.origin.x += deltaX / 2;
        } else {
            frame.origin.x += deltaX;
        }
    }

    if (autoresizingMask & kCALayerMinYMargin) {
        if (autoresizingMask & kCALayerMaxYMargin) {
            frame.origin.y += deltaY / 2;
        } else {
            frame.origin.y += deltaY;
        }
    }

    CGRect newFrame;

    if (self.view.alignsToIntegralPixels) {
        /*
         * Align the rectangle and save the difference, so that we can
         * compensate for it in later autoresizing.
         */
        newFrame = [self.view backingAlignedRect:frame];

        self.roundoffErrorX = CGRectGetMaxX(frame) - CGRectGetMaxX(newFrame);
        self.roundoffErrorY = CGRectGetMaxY(frame) - CGRectGetMaxY(newFrame);
    } else {
        newFrame = frame;
    }

    self.frame = newFrame;
}

@end
