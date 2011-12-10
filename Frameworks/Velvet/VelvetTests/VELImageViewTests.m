//
//  VELImageViewTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 08.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELImageViewTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@interface VELImageViewTests ()
- (NSImage *)image;
@end

@implementation VELImageViewTests

- (NSImage *)image {
    NSURL *URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"testimage" withExtension:@"jpg"];
    STAssertNotNil(URL, @"");

    NSImage *testImage = [[NSImage alloc] initWithContentsOfURL:URL];
    STAssertNotNil(testImage, @"");

    return testImage;
}

- (void)testImage {
    NSImage *testImage = [self image];

    VELImageView *imageView = [[VELImageView alloc] init];
    STAssertNotNil(imageView, @"");

    CGImageRef imageRef = testImage.CGImage;
    STAssertTrue(imageRef != NULL, @"");

    imageView.image = imageRef;
    STAssertEquals(imageView.image, imageRef, @"");
}

- (void)testSizing {
    NSImage *testImage = [self image];

    CGSize size = testImage.size;
    CGFloat aspectRatio = size.width / size.height;

    VELImageView *imageView = [[VELImageView alloc] init];
    imageView.image = testImage.CGImage;

    CGSize preferredSize = [imageView sizeThatFits:CGSizeZero];
    STAssertTrue(CGSizeEqualToSize(size, preferredSize), @"");

    // a larger available size should still return the actual size of the image
    CGSize largerSize = [imageView sizeThatFits:CGSizeMake(1000, 1000)];
    STAssertTrue(CGSizeEqualToSize(size, largerSize), @"");

    {
        CGSize constraint = CGSizeMake(size.width / 2, size.height / 5); 
        CGSize constrainedSize = [imageView sizeThatFits:constraint];

        NSLog(@"constrainedSize: %@", NSStringFromSize(constrainedSize));

        STAssertTrue(constrainedSize.width <= constraint.width, @"");
        STAssertTrue(constrainedSize.height <= constraint.height, @"");

        CGFloat constrainedAspectRatio = constrainedSize.width / constrainedSize.height;
        STAssertEqualsWithAccuracy(aspectRatio, constrainedAspectRatio, 0.01, @"");
    }

    {
        CGSize constraint = CGSizeMake(size.width / 5, size.height / 2); 
        CGSize constrainedSize = [imageView sizeThatFits:constraint];

        NSLog(@"constrainedSize: %@", NSStringFromSize(constrainedSize));

        STAssertTrue(constrainedSize.width <= constraint.width, @"");
        STAssertTrue(constrainedSize.height <= constraint.height, @"");

        CGFloat constrainedAspectRatio = constrainedSize.width / constrainedSize.height;
        STAssertEqualsWithAccuracy(aspectRatio, constrainedAspectRatio, 0.01, @"");
    }
}

@end
