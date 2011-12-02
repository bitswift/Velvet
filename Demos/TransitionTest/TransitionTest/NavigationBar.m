//
//  NavigationBar.m
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "NavigationBar.h"

@implementation NavigationBar
@synthesize openCloseButton = m_openCloseButton;

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.openCloseButton = [[RotatingControl alloc] init];
    self.openCloseButton.frame = CGRectMake(0, 0, 64, 44);
    self.openCloseButton.icon = [NSImage imageNamed:@"arrow.png"];
    [self addSubview:self.openCloseButton];

    self.layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
    return self;
}

@end
