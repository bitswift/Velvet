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

@synthesize frame = m_frame;
@synthesize layer = m_layer;

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
	
	// should this be CGRectNull instead?
	self.frame = CGRectZero;

	return self;
}

@end
