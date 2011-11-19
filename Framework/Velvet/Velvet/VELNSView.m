//
//  VELNSView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELNSView.h>
#import <Velvet/VELView.h>

@interface VELNSView () {
	/**
	 * Used to synchronize access to and operations around the `rootView`.
	 */
	dispatch_queue_t m_rootViewQueue;
	
	VELView *m_rootView;
}

@end

@implementation VELNSView

#pragma mark Properties

- (VELView *)rootView; {
	__block VELView *view = nil;

	dispatch_sync(m_rootViewQueue, ^{
		view = m_rootView;
	});

	return view;
}

- (void)setRootView:(VELView *)view; {
	dispatch_async(m_rootViewQueue, ^{
		[m_rootView.layer removeFromSuperlayer];
		m_rootView = view;

		if (view.layer)
			[self.layer addSublayer:view.layer];

		[self setNeedsDisplay:YES];
	});
}

#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame; {
    self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	m_rootViewQueue = dispatch_queue_create("com.emeraldlark.VELNSView.rootViewQueue", DISPATCH_QUEUE_SERIAL);
	
	// set up layer hosting
	CALayer *layer = [self makeBackingLayer];
	[self setLayer:layer];
	[self setWantsLayer:YES];

	return self;
}

- (void)dealloc {
	dispatch_release(m_rootViewQueue);
	m_rootViewQueue = NULL;
}

@end
