//
//  VELViewLayer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 14.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELViewLayer.h>
#import <Velvet/VELView.h>
#import <Proton/Proton.h>

@interface VELViewLayer ()
/*
 * The view that this layer is backing.
 */
@property (nonatomic, weak, readonly) VELView *view;

/*
 * How many fractions of a point belong in the X coordinate of the receiver's
 * `position`, but have been rounded off to keep the receiver on whole points.
 */
@property (nonatomic, assign) CGFloat roundoffErrorX;

/*
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

    if (self.view.alignsToIntegralPoints) {
        /*
         * Floor all coordinates and save the difference, so that we can
         * compensate for it in later autoresizing.
         */
        newFrame = CGRectMake(
            floor(frame.origin.x),
            ceil(frame.origin.y),
            floor(frame.size.width),
            floor(frame.size.height)
        );

        self.roundoffErrorX = CGRectGetMaxX(frame) - CGRectGetMaxX(newFrame);
        self.roundoffErrorY = CGRectGetMaxY(frame) - CGRectGetMaxY(newFrame);
    } else {
        newFrame = frame;
    }

    self.frame = newFrame;
}

@end
