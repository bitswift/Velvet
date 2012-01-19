//
//  NSImage+CoreGraphicsAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/NSImage+CoreGraphicsAdditions.h>
#import "EXTSafeCategory.h"

@safecategory (NSImage, CoreGraphicsAdditions)
- (CGImageRef)CGImage; {
    NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
    return [self CGImageForProposedRect:NULL context:graphicsContext hints:nil];
}

- (id)initWithCGImage:(CGImageRef)image; {
    return [self initWithCGImage:image size:NSZeroSize];
}
@end
