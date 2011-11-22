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

/**
 * The affine transform needed to move into the coordinate system of the
 * receiver from its superview.
 */
@property (readonly) CGAffineTransform affineTransformFromSuperview;
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
	dispatch_sync_recursive(self.context.dispatchQueue, ^{
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
		dispatch_sync_recursive(self.context.dispatchQueue, ^{
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
		dispatch_sync_recursive(selfContext.dispatchQueue, block);
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

- (VELView *)ancestorSharedWithView:(VELView *)view; {
	VELView *parentView = self;

	do {
		if ([view isDescendantOfView:parentView])
			return parentView;

		parentView = parentView.superview;
	} while (parentView);

	return nil;
}

- (BOOL)isDescendantOfView:(VELView *)view; {
	NSParameterAssert(view != nil);

	VELView *testView = self;
	do {
		if (testView == view)
			return YES;

		testView = testView.superview;
	} while (testView);

	return NO;
}

- (void)removeFromSuperview; {
	dispatch_sync_recursive(self.context.dispatchQueue, ^{
		[self.layer removeFromSuperlayer];
		self.superview = nil;
	});
}

#pragma mark Geometry

- (CGAffineTransform)affineTransformFromSuperview {
	// this will expand in the future to include a 'transform' property
	CGRect frame = self.frame;
	return CGAffineTransformMakeTranslation(frame.origin.x, frame.origin.y);
}

- (CGAffineTransform)affineTransformToView:(VELView *)view; {
	VELView *parentView = [self ancestorSharedWithView:view];
	NSAssert(parentView != nil, @"views must share an ancestor in order for an affine transform between them to be valid");

	// FIXME: this is a really naive implementation

	// returns the transformation needed to get from 'fromView' to
	// 'parentView'
	CGAffineTransform (^transformFromView)(VELView *) = ^(VELView *fromView){
		CGAffineTransform affineTransform = CGAffineTransformIdentity;

		while (fromView != parentView) {
			// work backwards, getting the transformation from the superview to
			// the subview
			CGAffineTransform invertedTransform = fromView.affineTransformFromSuperview;

			// then invert that, to get the other direction
			affineTransform = CGAffineTransformConcat(affineTransform, CGAffineTransformInvert(invertedTransform));

			fromView = fromView.superview;
		}

		return affineTransform;
	};

	// get the transformation from self to 'parentView'
	CGAffineTransform transformFromSelf = transformFromView(self);

	// get the transformation from 'parentView' to 'view'
	CGAffineTransform transformFromOther = transformFromView(view);
	CGAffineTransform transformToOther = CGAffineTransformInvert(transformFromOther);

	// combine the two
	return CGAffineTransformConcat(transformFromSelf, transformToOther);
}

- (CGPoint)convertPoint:(CGPoint)point fromView:(VELView *)view; {
	CGAffineTransform transform = CGAffineTransformInvert([self affineTransformToView:view]);
	return CGPointApplyAffineTransform(point, transform);
}

- (CGPoint)convertPoint:(CGPoint)point toView:(VELView *)view; {
	CGAffineTransform transform = [self affineTransformToView:view];
	return CGPointApplyAffineTransform(point, transform);
}

- (CGRect)convertRect:(CGRect)rect fromView:(VELView *)view; {
	CGAffineTransform transform = CGAffineTransformInvert([self affineTransformToView:view]);
	return CGRectApplyAffineTransform(rect, transform);
}

- (CGRect)convertRect:(CGRect)rect toView:(VELView *)view; {
	CGAffineTransform transform = [self affineTransformToView:view];
	return CGRectApplyAffineTransform(rect, transform);
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
		kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host
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

	CGContextSetShouldSmoothFonts(context, YES);

	NSGraphicsContext *previousGraphicsContext = [NSGraphicsContext currentContext];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
	[NSGraphicsContext setCurrentContext:graphicsContext];

	[self drawRect:bounds];
	
	[NSGraphicsContext setCurrentContext:previousGraphicsContext];
}

@end
