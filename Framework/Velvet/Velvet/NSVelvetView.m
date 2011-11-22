//
//  NSVelvetView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/NSVelvetView.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELView.h>
#import <Velvet/VELViewPrivate.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface NSVelvetView ()
@property (nonatomic, strong) NSView *velvetHostView;
@property (nonatomic, readwrite, strong) VELContext *context;

/**
 * Configures all the necessary properties on the receiver. This is outside of
 * an initializer because \c NSView has no true designated initializer.
 */
- (void)setUp;
@end

/**
 * Private layer-hosted view class, containing the whole Velvet view hierarchy.
 * This class needs to be a subview of an NSVelvetView, because the latter is
 * layer-backed (not layer-hosted).
 */
@interface NSVelvetHostView : NSView
/**
 * Configures all the necessary properties on the receiver. This is outside of
 * an initializer because \c NSView has no true designated initializer.
 */
- (void)setUp;
@end

@implementation NSVelvetView

#pragma mark Properties

@synthesize context = m_context;
@synthesize rootView = m_rootView;
@synthesize velvetHostView = m_velvetHostView;

- (void)setRootView:(VELView *)view; {
	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	[m_rootView.layer removeFromSuperlayer];
	[self.velvetHostView.layer addSublayer:view.layer];

	m_rootView.hostView = nil;
	view.hostView = self;

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

	// enable layer-backing for this view (as high as possible in the view
	// hierarchy, to keep as much as possible in CA)
	[self setWantsLayer:YES];

	self.velvetHostView = [[NSVelvetHostView alloc] initWithFrame:self.bounds];
	self.velvetHostView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[self addSubview:self.velvetHostView];

	self.rootView = [[VELView alloc] init];
}

#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize; {
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	self.rootView.layer.frame = self.velvetHostView.layer.frame = self.bounds;
	[CATransaction commit];
}

@end

@implementation NSVelvetHostView

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
	// set up layer hosting for Velvet
	CALayer *layer = [CALayer layer];
	[self setLayer:layer];
	[self setWantsLayer:YES];
}

#pragma mark Rendering

- (BOOL)needsDisplay {
	return [self.layer needsDisplay];
}

@end
