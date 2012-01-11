//
//  RotatingControl.h
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>

@interface RotatingControl : VELControl
@property (nonatomic, assign, getter = isUpward) BOOL upward;
@property (nonatomic, strong) NSImage *icon;

- (void)setUpward:(BOOL)value animated:(BOOL)animated;
@end
