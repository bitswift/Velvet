//
//  EditorView.m
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "EditorView.h"

@implementation EditorView
@synthesize screenView = m_screenView;
@synthesize deviceFrame = m_deviceFrame;

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.screenView = [[VELImageView alloc] init];
    [self addSubview:self.screenView];

    self.deviceFrame = [[VELImageView alloc] init];
    self.deviceFrame.image = [NSImage imageNamed:@"device.png"].CGImage;
    self.deviceFrame.alpha = 0;
    [self addSubview:self.deviceFrame];

    return self;
}

@end
