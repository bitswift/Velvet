//
//  VELImageView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELImageView.h>

@implementation VELImageView

#pragma mark Properties

- (CGImageRef)image {
    return (__bridge CGImageRef)self.layer.contents;
}

- (void)setImage:(CGImageRef)image {
    self.layer.contents = (__bridge id)image;
}

- (NSEdgeInsets)endCapInsets {
    size_t width = CGImageGetWidth(self.image);
    size_t height = CGImageGetHeight(self.image);

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
    size_t width = CGImageGetWidth(self.image);
    size_t height = CGImageGetHeight(self.image);

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
    self.contentMode = VELViewContentModeScaleToFill;
    return self;
}

- (id)initWithImage:(CGImageRef)image; {
    self = [self init];
    if (!self)
        return nil;

    self.image = image;
    self.bounds = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
    return self;
}

#pragma mark Layout

- (CGSize)sizeThatFits:(CGSize)size {
    CGImageRef image = self.image;
    if (!image)
        return CGSizeZero;

    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    if (!width || !height)
        return CGSizeZero;

    CGSize actualSize = CGSizeMake(width, height);

    if (fabs(size.width) < 0.01)
        size.width = CGFLOAT_MAX;

    if (fabs(size.height) < 0.01)
        size.height = CGFLOAT_MAX;

    if (size.width >= width && size.height >= height) {
        // the given constraint is bigger than the image, so just use the
        // image's actual size
        return actualSize;
    }

    CGFloat aspectRatio = (CGFloat)width / height;
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
