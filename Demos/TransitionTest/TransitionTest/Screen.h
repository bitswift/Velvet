//
//  Screen.h
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 30.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>

@interface Screen : VELView
@property (nonatomic, strong, readonly) VELImageView *thumbnailImageView;
@end
