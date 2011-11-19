//
//  VELView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>

@interface VELView ()
@end

@implementation VELView

#pragma mark Properties

@synthesize origin = m_origin;
@synthesize bounds = m_bounds;
@synthesize layer = m_layer;

- (CGRect)frame {
	// TODO: this needs proper synchronization
	CGRect bounds = self.bounds;
	CGPoint origin = self.origin;

	return CGRectMake(
		origin.x - bounds.size.width / 2,
		origin.y - bounds.size.height / 2,
		bounds.size.width,
		bounds.size.height
	);
}

- (void)setFrame:(CGRect)frame {
	// TODO: this needs proper synchronization
	CGRect previousBounds = self.bounds;

	self.origin = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2);
	self.bounds = CGRectMake(previousBounds.origin.x, previousBounds.origin.y, frame.size.width, frame.size.height);
}

#pragma mark Layer handling

+ (Class)layerClass; {
	return [CALayer class];
}

#pragma mark Lifecycle

- (id)init; {
	self = [super init];
	if (!self)
		return nil;

	// we don't even provide a setter for this ivar, because it should never
	// change after initialization
	m_layer = [[[self class] layerClass] layer];
	m_layer.delegate = self;

	return self;
}

#pragma mark Rendering

- (void)drawRect:(CGRect)rect; {
}

#pragma mark CALayer delegate

- (void)displayLayer:(CALayer *)layer {
	CGSize size = self.bounds.size;
	size_t width = (size_t)ceil(size.width);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(
		NULL,
		width,
		(size_t)ceil(size.height),
		8,
		width * 4,
		colorSpace,
		kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host
	);

	CGColorSpaceRelease(colorSpace);

	[self drawLayer:layer inContext:context];

	CGImageRef image = CGBitmapContextCreateImage(context);
	layer.contents = (__bridge_transfer id)image;

	CGContextRelease(context);
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
	CGContextClearRect(context, self.frame);
}

@end
