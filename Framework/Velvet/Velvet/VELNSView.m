//
//  VELNSView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELNSView.h>

@implementation VELNSView
- (id)initWithFrame:(NSRect)frame; {
    self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	// set up layer hosting
	CALayer *layer = [self makeBackingLayer];
	[self setLayer:layer];
	[self setWantsLayer:YES];
	return self;
}

@end
