//
//  ADDraggingDestinationView.m
//  AppKitAnimationDemo
//
//  Created by Josh Vera on 11/29/11.
//  Copyright (c) 2011 Übermind, Inc. All rights reserved.
//

#import "ADDraggingDestinationView.h"

@implementation ADDraggingDestinationView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;

    const CGFloat redColor[] = {1.0, 0.0, 0.0, 1.0};
    CGContextSetFillColor(context, redColor);
    CGContextFillRect(context, dirtyRect);
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSLog(@"draggingEntered:");
    return NSDragOperationEvery;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    NSLog(@"draggingUpdated:");
    return NSDragOperationEvery;
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
