//
//  NSImage+CoreGraphicsAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/NSImage+CoreGraphicsAdditions.h>
#import <Proton/EXTSafeCategory.h>

@safecategory (NSImage, CoreGraphicsAdditions)
- (CGImageRef)CGImage; {
    return [self CGImageForProposedRect:NULL context:nil hints:nil];
}

- (id)initWithCGImage:(CGImageRef)image; {
    return [self initWithCGImage:image size:NSZeroSize];
}
@end
