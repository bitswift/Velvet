//
//  VELDraggingDestination.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 10.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * Implemented by <VELView> classes that support drag-and-drop.
 */
@protocol VELDraggingDestination <NSDraggingDestination>
@required
/**
 * Returns the Uniform Type Identifiers accepted by the receiver when
 * functioning as a drag-and-drop destination.
 *
 * This method should return the same value for as long as it is part of a view
 * hierarchy on screen. In other words, this array may only change while the
 * view doesn't have a <[VELView hostView]>.
 */
- (NSArray *)supportedDragTypes;
@end
