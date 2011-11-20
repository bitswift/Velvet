//
//  VELNSView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELNSView.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELView.h>
#import <Velvet/VELViewPrivate.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface VELNSView ()
@property (nonatomic, readwrite, strong) VELContext *context;

/**
 * Configures all the necessary properties on the receiver. This is outside of
 * an initializer because \c NSView has no true designated initializer.
 */
- (void)setUp;
@end

@implementation VELNSView

#pragma mark Properties

@synthesize context = m_context;
@synthesize rootView = m_rootView;

- (void)setRootView:(VELView *)view; {
	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	[m_rootView.layer removeFromSuperlayer];
	[self.layer addSublayer:view.layer];

	m_rootView.NSView = nil;
	view.NSView = self;

	m_rootView = view;

	[CATransaction commit];
}

#pragma mark Lifecycle

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
	if (!self)
		return nil;
	
	[self setUp];
	return self;
}

- (id)initWithFrame:(NSRect)frame; {
    self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	[self setUp];
	return self;
}

- (void)setUp; {
	self.context = [[VELContext alloc] init];
	
	// set up layer hosting
	CALayer *layer = [CALayer layer];
	[self setLayer:layer];
	[self setWantsLayer:YES];
}

#pragma mark Rendering

- (BOOL)needsDisplay {
	return [self.layer needsDisplay];
}

@end
