//
//  VELNSView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELNSView.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELViewPrivate.h>


@implementation VELNSView

#pragma mark Properties

@synthesize NSView = m_NSView;

- (NSView *)NSView {
	__block NSView *view;

	dispatch_sync_recursive(self.context.dispatchQueue, ^{
		view = m_NSView;
	});

	return view;
}

- (void)setNSView:(NSView *)view {
	[view setWantsLayer:YES];

	dispatch_sync_recursive(self.context.dispatchQueue, ^{
		if (view != m_NSView) [m_NSView removeFromSuperview];

		view.frame = [self.superview convertRect:self.frame toView:self.hostView.rootView];

		if (view != m_NSView) {
			[self.hostView addSubview:view];
			m_NSView = view;
		}
	});
}

#pragma mark Lifecycle

- (id)init {
	self = [super init];
	if (!self)
		return nil;

	return self;
}

- (id)initWithNSView:(NSView *)view; {
	self = [self init];
	if (!self)
		return nil;

	self.NSView = view;
	return self;
}

#pragma mark CALayer delegate

- (void)displayLayer:(CALayer *)layer {
	[self.NSView.layer displayIfNeeded];
	id contents = self.NSView.layer.contents;
	if (contents) {
		layer.contents = contents;
	} else {
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
			kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host
		);

		CGColorSpaceRelease(colorSpace);

		[self.NSView.layer renderInContext:context];

		CGImageRef image = CGBitmapContextCreateImage(context);
		layer.contents = (__bridge_transfer id)image;

		CGContextRelease(context);
	}
}

@end
