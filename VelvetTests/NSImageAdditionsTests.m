//
//  NSImageAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 29.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/NSImage+TransformationAdditions.h>

SpecBegin(NSImageAdditions)
    
    __block NSImage *highDensityImage;
    __block CGSize highDensitySize;

    before(^{
        NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"high-density-test" withExtension:@"png"];

        highDensityImage = [[NSImage alloc] initByReferencingURL:imageURL];
        expect(highDensityImage).not.toBeNil();

        highDensitySize = highDensityImage.size;

        // this is the pixel size of the image, which should not be the
        // -[NSImage size] yet
        expect(highDensitySize).not.toEqual(CGSizeMake(512, 512));
    });

    after(^{
        // the original image should be unmodified
        expect(highDensityImage.size).toEqual(highDensitySize);
    });

    it(@"should return a new image with scale factor 1", ^{
        NSImage *scaledImage = [highDensityImage imageWithScale:1];
        expect(scaledImage.size).toEqual(CGSizeMake(512, 512));
    });

    it(@"should return a new image with scale factor 0.5", ^{
        NSImage *scaledImage = [highDensityImage imageWithScale:0.5];
        expect(scaledImage.size).toEqual(CGSizeMake(1024, 1024));
    });

    it(@"should return a new image with scale factor 2", ^{
        NSImage *scaledImage = [highDensityImage imageWithScale:2];
        expect(scaledImage.size).toEqual(CGSizeMake(256, 256));
    });

SpecEnd
