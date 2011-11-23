//
//  VELCAAction.h
//  Velvet
//
//  Created by James Lawton on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/**
 * A CAAction which finds NSViews contained in Velvet and animated them alongside.
 * We pass through to the default animation to animate the Velvet views.
 */
@interface VELCAAction : NSObject <CAAction>

+ (id)actionWithAction:(id <CAAction>)innerAction;

@property (strong) id delegate;

+ (BOOL)interceptsActionForKey:(NSString *)key;

@end
