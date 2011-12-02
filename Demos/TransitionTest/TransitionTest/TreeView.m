//
//  TreeView.m
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "TreeView.h"

@implementation TreeView
@synthesize screens = m_screens;
@synthesize selectedScreen = m_selectedScreen;

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.selectedScreen = [[Screen alloc] init];
    self.selectedScreen.bounds = CGRectMake(0, 0, 64.0f, 96.0f);
    self.selectedScreen.autoresizingMask = VELAutoresizingFlexibleLeftMargin | VELAutoresizingFlexibleTopMargin | VELAutoresizingFlexibleRightMargin | VELAutoresizingFlexibleBottomMargin;
    [self addSubview:self.selectedScreen];

    self.selectedScreen.center = self.center;
    self.layer.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"pattern.png"]].CGColor;

    self.screens = [NSMutableArray arrayWithObject:self.selectedScreen];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    for (Screen *screen in self.screens) {
        screen.center = self.center;
    }
}

@end
