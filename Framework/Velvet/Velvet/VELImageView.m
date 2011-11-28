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

#pragma mark CALayer delegate

- (void)displayLayer:(CALayer *)layer {
}

@end
