//
//  VELView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/VELContext.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/VELViewPrivate.h>

@interface VELView ()
@property (readwrite, weak) VELView *superview;
@property (readwrite, weak) NSVelvetView *hostView;
@property (readwrite, strong) VELContext *context;
@end

@implementation VELView

#pragma mark Properties

@synthesize layer = m_layer;
@synthesize subviews = m_subviews;
@synthesize superview = m_superview;
@synthesize hostView = m_hostView;

// TODO: we should probably flush the GCD queue of an old context before
// accepting a new one (to make sure there are no race conditions during
// a transition)
@synthesize context = m_context;

- (CGRect)frame {
	return self.layer.frame;
}

- (void)setFrame:(CGRect)frame {
	self.layer.frame = frame;
	[self.layer setNeedsDisplay];
}

- (CGRect)bounds {
	return self.layer.bounds;
}

- (void)setBounds:(CGRect)bounds {
	self.layer.bounds = bounds;
	[self.layer setNeedsDisplay];
}

- (CGPoint)center {
	return self.layer.position;
}

- (void)setCenter:(CGPoint)center {
	self.layer.position = center;
}

- (NSArray *)subviews {
	__block NSArray *subviews = nil;

	dispatch_sync_recursive(self.context.dispatchQueue, ^{
		subviews = [m_subviews copy];
	});
	
	return subviews;
}

- (void)setSubviews:(NSArray *)subviews {
	dispatch_async_recursive(self.context.dispatchQueue, ^{
		for (VELView *view in m_subviews) {
			[view removeFromSuperview];
		}

		m_subviews = [subviews copy];
		for (VELView *view in m_subviews) {
			if (!view.context) {
				view.context = self.context;
			} else if (!self.context) {
				self.context = view.context;
			} else {
				NSAssert([view.context isEqual:self.context], @"VELContext of a new subview should match that of its superview");
			}

			view.superview = self;
			[self.layer addSublayer:view.layer];
		}
	});
}

- (NSVelvetView *)hostView {
  	__block NSVelvetView *view = nil;

  	dispatch_sync_recursive(self.context.dispatchQueue, ^{
		view = m_hostView;
	});

	if (view)
		return view;
	else
		return self.superview.hostView;
}

- (void)setHostView:(NSVelvetView *)view {
	// TODO: the threading here isn't really safe, since it depends on having
	// a valid context with which to synchronize -- sometimes there may be no
	// context, which could introduce race conditions

	if (!view) {
		dispatch_async_recursive(self.context.dispatchQueue, ^{
			m_hostView = nil;
			self.context = nil;
		});

		return;
	}

	VELContext *selfContext = self.context;
	VELContext *viewContext = view.context;

	dispatch_block_t block = ^{
		m_hostView = view;
		self.context = viewContext;
	};

	if (selfContext != viewContext) {
		// if 'selfContext' is NULL, it will (intentionally) short-circuit the list
		// of arguments here
		dispatch_multibarrier_async(block, viewContext.dispatchQueue, selfContext.dispatchQueue, NULL);
	} else {
		dispatch_async_recursive(selfContext.dispatchQueue, block);
	}
}

- (NSWindow *)window {
	return self.hostView.window;
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

#pragma mark View hierarchy

- (void)removeFromSuperview; {
	dispatch_async_recursive(self.context.dispatchQueue, ^{
		[self.layer removeFromSuperlayer];
		self.superview = nil;
	});
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
	CGRect bounds = self.bounds;

	CGContextClearRect(context, bounds);
	CGContextClipToRect(context, bounds);

	NSGraphicsContext *previousGraphicsContext = [NSGraphicsContext currentContext];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
	[NSGraphicsContext setCurrentContext:graphicsContext];

	[self drawRect:bounds];
	
	[NSGraphicsContext setCurrentContext:previousGraphicsContext];
}

@end
