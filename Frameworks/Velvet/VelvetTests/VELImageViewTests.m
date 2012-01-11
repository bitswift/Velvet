//
//  VELImageViewTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 08.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELImageViewTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@interface VELImageViewTests ()
@property (nonatomic, strong, readonly) NSImage *image;
@end

@implementation VELImageViewTests

- (NSImage *)image {
    NSURL *URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"testimage" withExtension:@"jpg"];
    STAssertNotNil(URL, @"");

    NSImage *testImage = [[NSImage alloc] initWithContentsOfURL:URL];
    STAssertNotNil(testImage, @"");

    return testImage;
}

- (void)testInitialization {
    VELImageView *imageView = [[VELImageView alloc] init];
    STAssertNotNil(imageView, @"");

    STAssertTrue(!imageView.image, @"");

    NSEdgeInsets zeroInsets = NSEdgeInsetsMake(0, 0, 0, 0);
    STAssertTrue(NSEqualEdgeInsets(imageView.endCapInsets, zeroInsets), @"");
}

- (void)testInitializationWithImage {
    NSImage *image = [self image];
    CGImageRef CGImage = image.CGImage;

    VELImageView *imageView = [[VELImageView alloc] initWithImage:CGImage];
    STAssertNotNil(imageView, @"");

    STAssertEquals(imageView.image, CGImage, @"");
    STAssertTrue(CGSizeEqualToSize(imageView.bounds.size, image.size), @"");

    NSEdgeInsets zeroInsets = NSEdgeInsetsMake(0, 0, 0, 0);
    STAssertTrue(NSEqualEdgeInsets(imageView.endCapInsets, zeroInsets), @"");
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

- (void)testEndCapInsetsUpdatesContentStretch {
    NSImage *image = self.image;
    VELImageView *imageView = [[VELImageView alloc] initWithImage:image.CGImage];

    // top, left, bottom, right
    imageView.endCapInsets = NSEdgeInsetsMake(4, 2, 4, 2);

    CGRect contentStretch = imageView.contentStretch;

    CGFloat expectedXInset = (2 / image.size.width);
    CGFloat expectedYInset = (4 / image.size.height);
    
    STAssertEqualsWithAccuracy(contentStretch.origin.x, expectedXInset, 0.00001, @"");
    STAssertEqualsWithAccuracy(contentStretch.origin.y, expectedYInset, 0.00001, @"");
    STAssertEqualsWithAccuracy(contentStretch.size.width, 1.0 - expectedXInset * 2, 0.00001, @"");
    STAssertEqualsWithAccuracy(contentStretch.size.height, 1.0 - expectedYInset * 2, 0.00001, @"");
}

- (void)testEndCapInsetsReadsContentStretch {
    NSImage *image = self.image;
    VELImageView *imageView = [[VELImageView alloc] initWithImage:image.CGImage];

    imageView.contentStretch = CGRectMake(0.2, 0.25, 0.6, 0.5);

    // top, left, bottom, right
    NSEdgeInsets expectedEndCapInsets = NSEdgeInsetsMake(
        round(image.size.height * 0.25),
        round(image.size.width * 0.2),
        round(image.size.height * 0.25),
        round(image.size.width * 0.2)
    );
    
    STAssertTrue(NSEqualEdgeInsets(imageView.endCapInsets, expectedEndCapInsets), @"");
}

@end
