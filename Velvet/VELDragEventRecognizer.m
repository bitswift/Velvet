//
//  VELDragEventRecognizer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 06.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELDragEventRecognizer.h"
#import "CGGeometry+ConvenienceAdditions.h"
#import "VELBridgedView.h"
#import "VELEventRecognizerProtected.h"

@interface VELDragEventRecognizer ()
/**
 * The last known location of an event, relative to the window.
 */
@property (nonatomic, assign) CGPoint locationInWindow;

/**
 * The location of the mouse down event that started the drag, relative to the
 * window.
 */
@property (nonatomic, assign) CGPoint initialLocationInWindow;

/**
 * Whether the shift key was pressed during the last event passed to
 * <[VELEventRecognizer handleEvent:]>.
 */
@property (nonatomic, getter = isShiftPressed) BOOL shiftPressed;

/**
 * Whether the recognizer has seen an `NSMouseDown` event that hasn't yet been
 * acted on to transition between states.
 *
 * A drag requires a mouse down before it will transition into
 * `VELEventRecognizerStateBegan`.
 */
@property (nonatomic) BOOL didMouseDown;

/**
 * Returns a vector of `delta` projected to the nearest angle that is a multiple
 * of `interval` degrees.
 *
 * @param delta A vector to project to a nearby angle.
 * @param interval An angle multiplier to project to.
 */
- (CGPoint)projectedVector:(CGPoint)delta angularInterval:(CGFloat)interval;

/**
 * Updates <shiftPressed> from the information in the given event, returning
 * whether the update should result in an update to the recognizer state.
 */
- (BOOL)updateModifiers:(NSEvent *)event;
@end

@implementation VELDragEventRecognizer

#pragma mark Properties

@synthesize minimumDistance = m_minimumDistance;
@synthesize shiftLocksAxes = m_shiftLocksAxes;
@synthesize locationInWindow = m_locationInWindow;
@synthesize initialLocationInWindow = m_initialLocationInWindow;
@synthesize shiftPressed = m_shiftPressed;
@synthesize didMouseDown = m_didMouseDown;

- (BOOL)isContinuous {
    return YES;
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    self.shiftLocksAxes = YES;
    return self;
}

#pragma mark Geometry

- (CGPoint)projectedVector:(CGPoint)delta angularInterval:(CGFloat)interval {
    CGFloat angle = CGPointAngleInDegrees(delta);
    CGFloat roundedAngle = round(angle / interval) * interval;

    // Project our current delta onto the roundedAngle.
    return CGPointProjectAlongAngle(delta, roundedAngle);
}

- (CGPoint)locationInView:(id<VELBridgedView>)view {
    return view ? [view convertFromWindowPoint:self.locationInWindow] : self.locationInWindow;
}

- (CGPoint)translationInView:(id<VELBridgedView>)view {
    CGPoint translation;

    if (view) {
        CGPoint initialViewPoint = [view convertFromWindowPoint:self.initialLocationInWindow];
        CGPoint currentViewPoint = [view convertFromWindowPoint:self.locationInWindow];

        translation = CGPointSubtract(currentViewPoint, initialViewPoint);
    } else {
        translation = CGPointSubtract(self.locationInWindow, self.initialLocationInWindow);
    }

    if (self.shiftLocksAxes && self.shiftPressed) {
        translation = [self projectedVector:translation angularInterval:45.0f];
    }

    return translation;
}

#pragma mark Event Handling

- (BOOL)handleEvent:(NSEvent *)event {
    switch (event.type) {
        case NSLeftMouseDown: {
            if (self.didMouseDown) {
                return NO;
            }

            [super handleEvent:event];

            self.locationInWindow = self.initialLocationInWindow = event.locationInWindow;
            self.didMouseDown = YES;
            [self updateModifiers:event];

            // if there's (effectively) no minimum distance, begin recognition
            // immediately
            if (self.minimumDistance < 0.0001) {
                self.state = VELEventRecognizerStateBegan;
            }

            break;
        }

        case NSLeftMouseDragged:
        case NSLeftMouseUp: {
            self.locationInWindow = event.locationInWindow;

            BOOL shouldUpdate = NO;
            VELEventRecognizerState transitionToState = VELEventRecognizerStateChanged;

            if (self.active) {
                shouldUpdate = YES;

                if (event.type == NSLeftMouseUp)
                    transitionToState = VELEventRecognizerStateEnded;
            } else if (CGPointLength([self translationInView:nil]) >= self.minimumDistance) {
                if (self.didMouseDown) {
                    shouldUpdate = YES;
                    transitionToState = VELEventRecognizerStateBegan;
                }
            } else if (event.type == NSLeftMouseUp) {
                // transition to the Possible state again, and dispatch any
                // delayed events
                self.state = VELEventRecognizerStatePossible;
                return NO;
            }

            if (!shouldUpdate)
                return NO;

            [super handleEvent:event];
            [self updateModifiers:event];
            self.state = transitionToState;

            break;
        }

        case NSFlagsChanged: {
            [super handleEvent:event];

            if ([self updateModifiers:event] && self.active) {
                self.state = VELEventRecognizerStateChanged;
            }

            break;
        }

        default:
            return NO;
    }

    return YES;
}

- (BOOL)updateModifiers:(NSEvent *)event {
    BOOL oldShiftPressed = self.shiftPressed;
    self.shiftPressed = (event.modifierFlags & NSShiftKeyMask) != 0;

    return self.shiftLocksAxes && (self.shiftPressed != oldShiftPressed);
}

#pragma mark State Transitions

- (void)reset {
    [super reset];
    self.didMouseDown = NO;
}

@end
