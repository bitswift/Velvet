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
    self.screenView.bounds = CGRectMake(0, 0, 320, 480);
    [self addSubview:self.screenView];

    self.deviceFrame = [[VELImageView alloc] init];
    self.deviceFrame.image = [[NSImage imageNamed:@"device.png"] CGImage];
    [self.deviceFrame centeredSizeToFit];

    self.deviceFrame.alpha = 0;
    [self addSubview:self.deviceFrame];

    return self;
}

- (void)drawRect:(CGRect)rect {
    NSGradient *grad = [[NSGradient alloc] initWithStartingColor:[NSColor grayColor] endingColor:[NSColor blackColor]];
    [grad drawInRect:self.bounds angle:-90.0f];
}

- (void)layoutSubviews {
    BOOL hasImage = (self.screenView.image != nil);

    self.screenView.hidden = !hasImage;
    self.screenView.center = self.center;

    self.deviceFrame.hidden = !hasImage;
    self.deviceFrame.center = self.center;
}

- (void)editScreen:(Screen *)screen {
    self.screenView.image = screen.thumbnailImageView.image;
    [self setNeedsLayout];
    
    [VELView animateWithDuration:0.5 animations:^{
        self.deviceFrame.alpha = 1;
    }];
}

@end
