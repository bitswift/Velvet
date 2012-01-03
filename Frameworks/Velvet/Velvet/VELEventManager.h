//
//  VELEventManager.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 03.01.12.
//  Copyright (c) 2012 Emerald Lark. All rights reserved.
//

#import <AppKit/AppKit.h>

/*
 * Responsible for intercepting events and dispatching them to Velvet when
 * appropriate.
 */
@interface VELEventManager : NSObject

/*
 * @name Singleton
 */

/*
 * Returns the singleton instance of this class.
 */
+ (VELEventManager *)defaultManager;
@end
