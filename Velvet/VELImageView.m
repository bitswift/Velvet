//
//  VELImageView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELImageView.h"
#import "CATransaction+BlockAdditions.h"

@implementation VELImageView

#pragma mark Properties

@synthesize image = m_image;

- (void)setImage:(NSImage *)image {
    if (m_image == image)
        return;

    m_image = image;
    [CATransaction performWithDisabledActions:^{
        self.layer.contents = image;        
    }];
}

- (NSEdgeInsets)endCapInsets {
    CGFloat width = self.image.size.width;
    CGFloat height = self.image.size.height;

    CGRect contentStretch = self.contentStretch;

    // top, left, bottom, right
    return NSEdgeInsetsMake(
        round(CGRectGetMinY(contentStretch) * height),
        round(CGRectGetMinX(contentStretch) * width),
        round(height - CGRectGetMaxY(contentStretch) * height),
        round(width - CGRectGetMaxX(contentStretch) * width)
    );
}

- (void)setEndCapInsets:(NSEdgeInsets)insets {
    CGFloat width = self.image.size.width;
    CGFloat height = self.image.size.height;

    CGFloat xOrigin = insets.left / width;
    CGFloat yOrigin = insets.top / height;

    self.contentStretch = CGRectMake(
        xOrigin,
        yOrigin,
        1.0 - insets.right / width - xOrigin,
        1.0 - insets.bottom / height - yOrigin
    );
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.userInteractionEnabled = NO;
    return self;
}

- (id)initWithImage:(NSImage *)image; {
    self = [self init];
    if (!self)
        return nil;

    self.image = image;
    return self;
}

#pragma mark Layout

- (CGSize)sizeThatFits:(CGSize)size {
    if (!self.image)
        return CGSizeZero;

    CGSize actualSize = self.image.size;

    if (fabs(size.width) < 0.01)
        size.width = CGFLOAT_MAX;

    if (fabs(size.height) < 0.01)
        size.height = CGFLOAT_MAX;

    if (size.width >= actualSize.width && size.height >= actualSize.height) {
        // the given constraint is bigger than the image, so just use the
        // image's actual size
        return actualSize;
    }

    CGFloat aspectRatio = actualSize.width / actualSize.height;
    CGFloat constraintAspectRatio = size.width / size.height;

    if (fabs(constraintAspectRatio - aspectRatio) < 0.001) {
        // effectively the correct aspect ratio
        return actualSize;
    }

    if (constraintAspectRatio > aspectRatio) {
        // the given size is proportionally too wide, so match its height and
        // scale down width accordingly
        return CGSizeMake(round(size.height * aspectRatio), size.height);
    } else {
        // the given size is proportionally too tall, so match its width and
        // scale down height accordingly
        return CGSizeMake(size.width, round(size.width / aspectRatio));
    }
}

@end
