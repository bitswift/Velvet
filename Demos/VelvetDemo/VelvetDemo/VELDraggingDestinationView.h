//
//  VELDraggingDestinationView.h
//  VelvetDemo
//
//  Created by Josh Vera on 11/29/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/Velvet.h>
#import <AppKit/NSDragging.h>

@interface VELDraggingDestinationView : VELView <VELDraggingDestination>

@property (nonatomic, strong) NSString *name;

@end
