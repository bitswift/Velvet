//
//  EditorView.h
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>
#import "Screen.h"

@interface EditorView : VELView
- (void)editScreen:(Screen *)screen;

@property (nonatomic, strong) VELImageView *screenView;
@property (nonatomic, strong) VELImageView *deviceFrame;
@end
