//
//  NSVelvetHostView.h
//  Velvet
//
//  Created by Bryan Hansen on 11/23/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NSVelvetView;
/*
 * Private layer-hosted view class, containing the whole Velvet view hierarchy.
 * This class needs to be a subview of an <NSVelvetView>, because the latter is
 * layer-backed (not layer-hosted), in order to support a separate `NSView`
 * hierarchy.
 */
@interface NSVelvetHostView : NSView

/**
 * The layer-hosted `NSView` that is used to host the receiver's 
 * Velvet view hierarchy.
 */
@property (nonatomic, weak, readonly) NSVelvetView *velvetView;
@end
