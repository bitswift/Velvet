//
//  VELImageView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
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

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.userInteractionEnabled = NO;
    self.contentMode = VELViewContentModeScaleAspectFit;
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
