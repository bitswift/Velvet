//
//  NSEvent+ButtonStateAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 08.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSEvent+ButtonStateAdditions.h"
#import "EXTSafeCategory.h"
#import "EXTScope.h"

/**
 * Pulls out the mouse state information from the given event, setting the given
 * pointers on success. Returns whether the event actually had such information.
 *
 * @param event An event that may contain mouse information.
 * @param buttonMaskPtr If not `NULL`, and this method returns `YES`, this will be
 * filed in with a bitmask identifying the buttons currently pressed.
 * @param changeMaskPtr If not `NULL`, and this method returns `YES`, this will be
 * filed in with a bitmask identifying the buttons with changed states.
 */
static BOOL getEventButtonState (NSEvent *event, NSUInteger *buttonMaskPtr, NSUInteger *changeMaskPtr) {
    NSCParameterAssert(event != NULL);

    void (^setMasks)(NSUInteger, NSUInteger) = ^(NSUInteger buttonMask, NSUInteger changeMask){
        if (buttonMaskPtr)
            *buttonMaskPtr = buttonMask;

        if (changeMaskPtr)
            *changeMaskPtr = changeMask;
    };

    void (^setButtonDown)(BOOL) = ^(BOOL buttonDown){
        NSUInteger bit = (1U << event.buttonNumber);
        NSUInteger buttonMask = buttonDown ? bit : 0;

        setMasks(buttonMask, bit);
    };

    switch (event.type) {
        case NSLeftMouseUp:
        case NSRightMouseUp:
        case NSOtherMouseUp:
            setButtonDown(NO);
            return YES;

        case NSLeftMouseDown:
        case NSLeftMouseDragged:
        case NSRightMouseDown:
        case NSRightMouseDragged:
        case NSOtherMouseDown:
        case NSOtherMouseDragged:
            setButtonDown(YES);
            return YES;

        case NSSystemDefined:
            // this is a special subtype that's sent for mouse button updates
            if (event.subtype == 7) {
                setMasks((NSUInteger)event.data2, (NSUInteger)event.data1);
                return YES;
            }

        default:
            return NO;
    }
}

@safecategory (NSEvent, ButtonStateAdditions)

#pragma mark Properties

- (BOOL)hasMouseButtonState {
    return getEventButtonState(self, NULL, NULL);
}

- (NSUInteger)mouseButtonStateMask {
    NSUInteger buttonMask = 0;
    getEventButtonState(self, &buttonMask, NULL);

    return buttonMask;
}

- (NSUInteger)mouseButtonStateChangedMask {
    NSUInteger changeMask = 0;
    getEventButtonState(self, NULL, &changeMask);

    return changeMask;
}

#pragma mark Event Conversion

- (NSArray *)correspondingMouseEvents; {
    NSUInteger buttonMask = 0;
    NSUInteger changeMask = 0;

    if (!getEventButtonState(self, &buttonMask, &changeMask))
        return nil;

    CGEventRef selfCGEvent = self.CGEvent;
    if (!selfCGEvent) {
        NSLog(@"*** Could not get CGEvent for event %@", self);
        return nil;
    }

    CGEventSourceRef eventSource = CGEventCreateSourceFromEvent(selfCGEvent);
    @onExit {
        if (eventSource)
            CFRelease(eventSource);
    };

    CGPoint location = CGEventGetLocation(selfCGEvent);
    NSMutableArray *events = [NSMutableArray array];

    for (NSUInteger buttonIndex = 0; changeMask != 0; changeMask >>= 1, buttonMask >>= 1, ++buttonIndex) {
        if ((changeMask & 0x1) == 0)
            continue;

        BOOL buttonPressed = (buttonMask & 0x1);

        CGEventRef newEvent = CGEventCreateCopy(selfCGEvent);
        if (!newEvent) {
            NSAssert(NO, @"Could not create new mouse event for button index %u (pressed: %i)", (unsigned)buttonIndex, (int)buttonPressed);
            continue;
        }

        switch (buttonIndex) {
            case 0:
                CGEventSetType(newEvent, buttonPressed ? kCGEventLeftMouseDown : kCGEventLeftMouseUp);
                CGEventSetIntegerValueField(newEvent, kCGMouseEventButtonNumber, kCGMouseButtonLeft);
                break;

            case 1:
                CGEventSetType(newEvent, buttonPressed ? kCGEventRightMouseDown : kCGEventRightMouseUp);
                CGEventSetIntegerValueField(newEvent, kCGMouseEventButtonNumber, kCGMouseButtonRight);
                break;

            default:
                CGEventSetType(newEvent, buttonPressed ? kCGEventOtherMouseDown : kCGEventOtherMouseUp);
                CGEventSetIntegerValueField(newEvent, kCGMouseEventButtonNumber, buttonIndex);
        }

        NSEvent *event = [NSEvent eventWithCGEvent:newEvent];
        CFRelease(newEvent);

        [events addObject:event];
    }

    return events;
}

@end
