//
//  NSImage+TransformationAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSImage+TransformationAdditions.h"
#import "EXTSafeCategory.h"

@safecategory (NSImage, TransformationAdditions)

#pragma mark Density Adjustments

- (NSImage *)imageWithScale:(CGFloat)scale; {
    NSParameterAssert(scale > 0);

    NSInteger width = 0;
    NSInteger height = 0;

    for (NSImageRep *representation in self.representations) {
        if (representation.pixelsWide * representation.pixelsHigh > width * height) {
            width = representation.pixelsWide;
            height = representation.pixelsHigh;
        }
    }

    NSImage *newImage = [self copy];
    newImage.size = CGSizeMake(width / scale, height / scale);

    return newImage;
}

@end
