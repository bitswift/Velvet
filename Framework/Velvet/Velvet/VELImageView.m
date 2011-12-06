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
    return self;
}

#pragma mark Layout

- (CGSize)sizeThatFits:(CGSize)size {
    CGImageRef image = self.image;
    if (!image)
        return CGSizeZero;

    return CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
}

@end
