//
//  SquareView.m
//  VelvetDemo
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "SquareView.h"

@implementation SquareView

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;

    CGColorRef color = CGColorCreateGenericRGB(1, 0, 0, 1);
    CGContextSetFillColorWithColor(context, color);
    CGColorRelease(color);

    CGContextFillRect(context, self.bounds);
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSLog(@"mouseDown!");
}

- (void)mouseUp:(NSEvent *)theEvent {
    NSLog(@"mouseUp!");
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    NSLog(@"rightMouseDown!");

}

- (void)rightMouseUp:(NSEvent *)theEvent {
    NSLog(@"rightMouseUp!");

}
//- (void)mouseMoved:(NSEvent *)theEvent {
//    NSLog(@"mouseMoved!");
//}

- (void)mouseDragged:(NSEvent *)theEvent {
    NSLog(@"mouseDragged!");

}
- (void)rightMouseDragged:(NSEvent *)theEvent {
    NSLog(@"rightMouseDragged!");

}
- (void)mouseEntered:(NSEvent *)theEvent {
    NSLog(@"mouseEntered!");

}
- (void)mouseExited:(NSEvent *)theEvent {
    NSLog(@"mouseExited!");

}


@end
