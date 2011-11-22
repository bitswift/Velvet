//
//  VELTUIView.h
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>
#import <TwUI/TUIKit.h>

@interface VELTUIView : VELView

/*
 * The view displayed by the reciever
 */
@property (nonatomic, strong) TUIView *TUIView;

/*
 * Initializes the receiver, setting the TUIView property to view
 */
- (id)initWithTUIView:(TUIView *)view;
@end
