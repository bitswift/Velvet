//
//  NavigationBar.h
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>
#import "RotatingControl.h"

@interface NavigationBar : VELView
@property (nonatomic, strong) RotatingControl *openCloseButton;
@end
