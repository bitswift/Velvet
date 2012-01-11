//
//  TreeView.h
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>
#import "Screen.h"

@interface TreeView : VELView
@property (nonatomic, strong) NSArray *screens;
@property (nonatomic, strong) Screen *selectedScreen;
@end
