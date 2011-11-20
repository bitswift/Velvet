//
//  SquareView.m
//  VelvetDemo
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "SquareView.h"
#import <QuartzCore/QuartzCore.h>

@interface SquareView ()
@property (nonatomic, strong) NSButton *button;
@end

@implementation SquareView
@synthesize button = m_button;

- (id)init {
	self = [super init];
	if (!self)
		return nil;

	NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 80, 20)];
	[button setButtonType:NSMomentaryPushInButton];
	[button setBezelStyle:NSRoundedBezelStyle];
	[button setTitle:@"Test Button"];
	[button setWantsLayer:YES];
	self.button = button;

	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	[self.layer addSublayer:button.layer];
	[CATransaction commit];

	return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;

	CGColorRef color = CGColorCreateGenericRGB(1, 0, 0, 1);
	CGContextSetFillColorWithColor(context, color);
	CGColorRelease(color);

	CGContextFillRect(context, self.bounds);
}
@end
