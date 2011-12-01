//
//  ADDraggingDestinationView.m
//  AppKitAnimationDemo
//
//  Created by Josh Vera on 11/29/11.
//  Copyright (c) 2011 Übermind, Inc. All rights reserved.
//

#import "ADDraggingDestinationView.h"

@implementation ADDraggingDestinationView

@synthesize fillColor = m_fillColor;
@synthesize name = m_name;
@synthesize draggingEnabled = m_draggingEnabled;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    
    return self;
}

- (void)setDraggingEnabled:(BOOL)draggingEnabled
{
    if (m_draggingEnabled != draggingEnabled) {
        m_draggingEnabled = draggingEnabled;
        if (draggingEnabled) {
            [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
        } else {
            [self unregisterDraggedTypes];
        }
    }
}

#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect
{

    NSBezierPath* drawingPath = [NSBezierPath bezierPath];
    [drawingPath appendBezierPathWithRect:dirtyRect];

    if (self.fillColor) {
        [self.fillColor setFill];
        [drawingPath fill];
    }
    
    [[NSColor blackColor] setStroke];
    [drawingPath stroke];
}

#pragma mark Dragging operations

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    return NSDragOperationEvery;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    return NSDragOperationEvery;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: 0x%p name=%@>", NSStringFromClass([self class]), self, self.name];
}

@end
