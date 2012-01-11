//
//  ADDraggingDestinationView.h
//  AppKitAnimationDemo
//
//  Created by Josh Vera on 11/29/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ADDraggingDestinationView : NSView <NSDraggingDestination>

@property (nonatomic, strong) NSColor *fillColor;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign, getter = isDraggingEnabled) BOOL draggingEnabled;

@end
