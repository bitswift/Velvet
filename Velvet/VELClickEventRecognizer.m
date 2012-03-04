//
//  VELClickEventRecognizer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 04.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELClickEventRecognizer.h"
#import "VELBridgedView.h"
#import "VELEventRecognizerProtected.h"

@interface VELClickEventRecognizer ()
/**
 * The location of the first click, in the coordinate system of the window of
 * the receiver's <[VELEventRecognizer view]>.
 *
 * If no clicks have occurred yet, this will be `CGPointZero`.
 */
@property (nonatomic, assign) CGPoint windowClickLocation;
@end

@implementation VELClickEventRecognizer

#pragma mark Properties

@synthesize numberOfClicksRequired = m_numberOfClicksRequired;
@synthesize windowClickLocation = m_windowClickLocation;

- (BOOL)isDiscrete {
    return YES;
}

#pragma mark Event Handling

- (void)handleEvent:(NSEvent *)event; {
    [super handleEvent:event];

    if (event.type == NSLeftMouseDown && event.clickCount == 1) {
        // save the location and wait for a mouse up
        self.windowClickLocation = [event locationInWindow];
        return;
    }

    if (event.type != NSLeftMouseUp) {
        return;
    }

    if (event.clickCount <= 0) {
        self.state = VELEventRecognizerStateFailed;
    } else if ((NSUInteger)event.clickCount % self.numberOfClicksRequired == 0) {
        self.state = VELEventRecognizerStateRecognized;
    }
}

- (CGPoint)locationInView:(id<VELBridgedView>)view; {
    if (!view)
        return self.windowClickLocation;

    return [view convertFromWindowPoint:self.windowClickLocation];
}

#pragma mark Transitions and States

- (void)reset {
    [super reset];
    self.windowClickLocation = CGPointZero;
}

@end
