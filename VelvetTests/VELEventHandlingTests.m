//
//  VELEventHandlingTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>

// returns an NSUInteger mask combining the given mouse button numbers
#define BUTTON_MASK_FOR_BUTTONS(...) \
    ^{ \
        NSUInteger buttons[] = { __VA_ARGS__ }; \
        NSUInteger mask = 0; \
        \
        for (NSUInteger i = 0; i < sizeof(buttons) / sizeof(*buttons); ++i) { \
            NSUInteger button = buttons[i]; \
            \
            mask |= (1 << button); \
        } \
        \
        return mask; \
    }()

@interface NSEvent (SystemDefinedEventCreation)
+ (NSEvent *)systemDefinedMouseEventAtLocation:(CGPoint)location mouseButtonStateMask:(NSUInteger)buttonStateMask mouseButtonStateChangedMask:(NSUInteger)buttonStateChangedMask;
@end

SpecBegin(VELEventHandling)

    describe(@"converting system-defined events to real mouse events", ^{
        __block CGPoint location;

        // to be set by the 'it' blocks below
        __block NSEvent *systemEvent;
        __block NSUInteger buttonMask;
        __block NSUInteger changeMask;

        before(^{
            systemEvent = nil;
            buttonMask = 0;
            changeMask = 0;

            location = CGPointMake(320, 480);
        });

        it(@"should convert a left mouse down event", ^{
            buttonMask = BUTTON_MASK_FOR_BUTTONS(0);
            changeMask = BUTTON_MASK_FOR_BUTTONS(0);

            systemEvent = [NSEvent
                systemDefinedMouseEventAtLocation:location
                mouseButtonStateMask:buttonMask
                mouseButtonStateChangedMask:changeMask
            ];

            NSArray *mouseEvents = systemEvent.correspondingMouseEvents;
            expect(mouseEvents.count).toEqual(1);

            NSEvent *event = mouseEvents.lastObject;
            expect(event.type).toEqual(NSLeftMouseDown);
        });

        it(@"should convert a left mouse up event", ^{
            buttonMask = 0;
            changeMask = BUTTON_MASK_FOR_BUTTONS(0);

            systemEvent = [NSEvent
                systemDefinedMouseEventAtLocation:location
                mouseButtonStateMask:buttonMask
                mouseButtonStateChangedMask:changeMask
            ];

            NSArray *mouseEvents = systemEvent.correspondingMouseEvents;
            expect(mouseEvents.count).toEqual(1);

            NSEvent *event = mouseEvents.lastObject;
            expect(event.type).toEqual(NSLeftMouseUp);
        });

        it(@"should convert a left mouse down + right mouse up event", ^{
            buttonMask = BUTTON_MASK_FOR_BUTTONS(0);
            changeMask = BUTTON_MASK_FOR_BUTTONS(0, 1);

            systemEvent = [NSEvent
                systemDefinedMouseEventAtLocation:location
                mouseButtonStateMask:buttonMask
                mouseButtonStateChangedMask:changeMask
            ];

            NSArray *mouseEvents = systemEvent.correspondingMouseEvents;
            expect(mouseEvents.count).toEqual(2);

            NSEvent *leftEvent = [mouseEvents objectAtIndex:0];
            expect(leftEvent.type).toEqual(NSLeftMouseDown);

            NSEvent *rightEvent = [mouseEvents objectAtIndex:1];
            expect(rightEvent.type).toEqual(NSRightMouseUp);
        });

        it(@"should convert mouse down event for other mouse buttons 2 - 4", ^{
            buttonMask = BUTTON_MASK_FOR_BUTTONS(2, 3, 4);
            changeMask = BUTTON_MASK_FOR_BUTTONS(2, 3, 4);

            systemEvent = [NSEvent
                systemDefinedMouseEventAtLocation:location
                mouseButtonStateMask:buttonMask
                mouseButtonStateChangedMask:changeMask
            ];

            NSArray *mouseEvents = systemEvent.correspondingMouseEvents;
            expect(mouseEvents.count).toEqual(3);

            NSUInteger button = 2;
            for (NSEvent *event in mouseEvents) {
                expect(event.type).toEqual(NSOtherMouseDown);
                expect(event.buttonNumber).toEqual(button);

                ++button;
            }
        });

        after(^{
            // verify some invariants about the system event
            expect(systemEvent).not.toBeNil();
            expect(systemEvent.hasMouseButtonState).toBeTruthy();
            expect(systemEvent.mouseButtonStateMask).toEqual(buttonMask);
            expect(systemEvent.mouseButtonStateChangedMask).toEqual(changeMask);
            expect(systemEvent.window).toBeNil();

            // and the corresponding mouse events
            NSArray *mouseEvents = systemEvent.correspondingMouseEvents;
            expect(mouseEvents.count).toBeGreaterThan(0);

            for (NSEvent *event in mouseEvents) {
                expect(fabs(event.timestamp - systemEvent.timestamp)).toBeLessThan(0.0001);
                expect(event.window).toBeNil();

                expect(event.locationInWindow).toEqual(systemEvent.locationInWindow);
            }
        });
    });

SpecEnd

@implementation NSEvent (SystemDefinedEventCreation)
+ (NSEvent *)systemDefinedMouseEventAtLocation:(CGPoint)location mouseButtonStateMask:(NSUInteger)buttonStateMask mouseButtonStateChangedMask:(NSUInteger)buttonStateChangedMask; {
    return [NSEvent
        otherEventWithType:NSSystemDefined
        location:location
        modifierFlags:0
        timestamp:[[NSProcessInfo processInfo] systemUptime]
        windowNumber:0
        context:nil
        subtype:7 // special mouse event subtype
        data1:(NSInteger)buttonStateChangedMask
        data2:(NSInteger)buttonStateMask
    ];
}
@end
