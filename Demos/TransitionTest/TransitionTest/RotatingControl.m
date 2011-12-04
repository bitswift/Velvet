//
//  RotatingControl.m
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "RotatingControl.h"

@interface RotatingControl ()
@property (nonatomic, strong, readonly) VELImageView *iconImageView;
@end

@implementation RotatingControl
@synthesize upward = m_upward;
@synthesize icon = m_icon;
@synthesize iconImageView = m_iconImageView;

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_iconImageView = [[VELImageView alloc] init];
    m_iconImageView.autoresizingMask = VELViewAutoresizingFlexibleWidth | VELViewAutoresizingFlexibleHeight;
    m_iconImageView.contentMode = VELViewContentModeCenter;
    [self addSubview:m_iconImageView];

    CGColorRef backgroundColor = CGColorCreateGenericGray(0.0f, 0.0f);
    m_iconImageView.layer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);

    self.upward = NO;
    return self;
}

- (void)setIcon:(NSImage *)image {
    m_icon = image;
    self.iconImageView.image = [image CGImageForProposedRect:NULL context:NULL hints:NULL];
}

- (void)setUpward:(BOOL)value; {
    [self setUpward:value animated:NO];
}

- (void)setUpward:(BOOL)value animated:(BOOL)animated; {
    CGFloat rads = M_PI;
    if (value)
        rads *= 2;

    void (^changes)(void) = ^{
        self.transform = CGAffineTransformMakeRotation(rads);
    };

    m_upward = YES;

    if (animated) {
        [VELView animateWithDuration:0.45f animations:changes];
    } else {
        changes();
    }
}

@end
