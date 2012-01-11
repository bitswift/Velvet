//
//  VELDraggingDestinationView.m
//  VelvetDemo
//
//  Created by Josh Vera on 11/29/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELDraggingDestinationView.h"
#import <Velvet/VELImageView.h>

@implementation VELDraggingDestinationView

@synthesize name = m_name;

- (id)init {
    self = [super init];
    if (self) {
        self.layer.masksToBounds = YES;
    }
    return self;
}

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

- (NSArray *)supportedDragTypes {
    return [NSArray arrayWithObject:NSFilenamesPboardType];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
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

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    sender.animatesToDestination = YES;
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));

    NSPasteboard *pb = [sender draggingPasteboard];
    NSArray *filePaths = [pb propertyListForType:NSFilenamesPboardType];
    for (NSString *path in filePaths) {
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:fileURL];
        if (image) {
            VELImageView *imageView = [[VELImageView alloc] init];
            CGImageRef imageRef = [image CGImageForProposedRect:NULL context:NULL hints:NULL];
            imageView.image = imageRef;
            CGPoint dragPoint = [self convertFromWindowPoint:[sender draggingLocation]];
            imageView.frame = CGRectMake(dragPoint.x, dragPoint.y, image.size.width, image.size.height);
            [self addSubview:imageView];
        }
    }

    NSLog(@"NSDraggingInfo = %@", sender);

    return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
    NSLog(@"[%@ %@]", self.name ?: NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: 0x%p, name = %@>",
        NSStringFromClass([self class]), self, self.name];
}

@end
