//
//  VELAnimationManager.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 10.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * This private class is responsible for disabling implicit `NSView` animations.
 *
 * This class may be expanded in the future to add other global animation
 * capabilities.
 */
@interface VELAnimationManager : NSObject

/*
 * @name Singleton
 */

/*
 * Returns the singleton instance of this class.
 */
+ (VELAnimationManager *)defaultManager;

@end
