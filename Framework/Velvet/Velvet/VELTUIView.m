//
//  VELTUIView.m
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELTUIView.h"
#import <Velvet/VELContext.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>

@implementation VELTUIView
@synthesize TUIView = m_TUIView;

- (id)initWithTUIView:(TUIView *)view {
	self = [super init];
	if (!self)
		return nil;

	self.TUIView = view;
	return self;

}

- (TUIView *)TUIView {
	__block TUIView *view;

	dispatch_sync_recursive(self.context.dispatchQueue, ^{
		view = m_TUIView;
	});

	return view;
}

- (void)setTUIView:(TUIView *)view {
	dispatch_sync_recursive(self.context.dispatchQueue, ^{
		[self.layer addSublayer:view.layer];
		m_TUIView = view;
	});
}

@end
