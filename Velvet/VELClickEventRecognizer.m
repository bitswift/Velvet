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

/**
 * Marks the recognizer as having failed to recognize its event.
 */
- (void)fail;
@end

@implementation VELClickEventRecognizer

#pragma mark Properties

@synthesize numberOfClicksRequired = m_numberOfClicksRequired;
@synthesize windowClickLocation = m_windowClickLocation;

- (BOOL)isDiscrete {
    return YES;
}

#pragma mark Event Handling

- (BOOL)handleEvent:(NSEvent *)event; {
    if (event.type == NSLeftMouseDown) {
        if (event.clickCount == 1) {
            // save the location and wait for a mouse up
            self.windowClickLocation = [event locationInWindow];
        }

        [super handleEvent:event];
        return YES;
    }

    if (event.type != NSLeftMouseUp) {
        return NO;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fail) object:nil];
    if (event.clickCount <= 0) {
        [self fail];
        return NO;
    }

    [super handleEvent:event];

    if ((NSUInteger)event.clickCount % self.numberOfClicksRequired == 0) {
        self.state = VELEventRecognizerStateRecognized;
    } else {
        // fail if we don't receive a multi-click in time
        [self performSelector:@selector(fail) withObject:nil afterDelay:[NSEvent doubleClickInterval]];
    }

    return YES;
}

- (CGPoint)locationInView:(id<VELBridgedView>)view; {
    if (!view)
        return self.windowClickLocation;

    return [view convertFromWindowPoint:self.windowClickLocation];
}

#pragma mark Transitions and States

- (void)fail; {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fail) object:nil];
    self.state = VELEventRecognizerStateFailed;
}

- (void)reset {
    [super reset];
    self.windowClickLocation = CGPointZero;
}

@end
