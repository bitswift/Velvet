//
//  VELDraggingDestinationView.m
//  VelvetDemo
//
//  Created by Josh Vera on 11/29/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELDraggingDestinationView.h"

@implementation VELDraggingDestinationView

@synthesize name = m_name;

- (void)drawRect:(CGRect)rect {
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;

//    CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
//    CGContextSetFillColorWithColor(context, red);
//    CGColorRelease(red);
//    CGContextFillRect(context, self.bounds);

    CGColorRef black = CGColorCreateGenericRGB(0, 0, 0, 1);
    CGContextSetStrokeColorWithColor(context, black);
    CGColorRelease(black);
    CGContextStrokeRect(context, self.bounds);
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return NSDragOperationEvery;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return NSDragOperationEvery;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return YES;
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: 0x%p, name = %@>",
        NSStringFromClass([self class]), self, self.name];
}

@end
