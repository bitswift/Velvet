//
//  VELNSView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELNSView.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/VELContext.h>

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

	dispatch_async_recursive(self.context.dispatchQueue, ^{
		[m_NSView.layer removeFromSuperlayer];

		// TODO: keep all geometry in sync constantly
		[self.layer addSublayer:view.layer];

		m_NSView = view;
	});
}

#pragma mark Lifecycle

- (id)initWithNSView:(NSView *)view; {
	self = [self init];
	if (!self)
		return nil;
	
	self.NSView = view;
	return self;
}

@end
