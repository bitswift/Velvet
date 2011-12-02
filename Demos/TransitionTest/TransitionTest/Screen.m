//
//  Screen.m
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 30.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "Screen.h"

@implementation Screen
@synthesize thumbnailImageView = m_thumbnailImageView;

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_thumbnailImageView = [[VELImageView alloc] initWithFrame:self.bounds];
    m_thumbnailImageView.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable; 
    m_thumbnailImageView.image = [[NSImage imageNamed:@"screen.png"] CGImageForProposedRect:NULL context:nil hints:nil];
    [self addSubview:m_thumbnailImageView];
    
    CGColorRef shadowColor = CGColorCreateGenericGray(0.0f, 1.0f);
    self.layer.shadowColor = shadowColor;
    CGColorRelease(shadowColor);
    
    self.layer.shadowOffset = CGSizeMake(0, -2);
    self.layer.shadowRadius = 2.0f;
    self.layer.shadowOpacity = 0.5f;
    return self;
}

@end
