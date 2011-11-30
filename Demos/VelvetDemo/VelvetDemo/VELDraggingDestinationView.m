//
//  VELDraggingDestinationView.m
//  VelvetDemo
//
//  Created by Josh Vera on 11/29/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELDraggingDestinationView.h"

@implementation VELDraggingDestinationView

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSLog(@"draggingEntered:");
    return NSDragOperationEvery;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    NSLog(@"draggingUpdated:");
    return NSDragOperationEvery;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    NSLog(@"draggingExited:");
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    NSLog(@"draggingEnded:");
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
    NSLog(@"prepareForDragOperation:");
    return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
    NSLog(@"performDragOperation:");
    return YES;
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender {
    NSLog(@"concludeDragOperation:");
}

@end
