//
//  VELEventHandlingTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 22.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>
#import <Velvet/VELEventRecognizerProtected.h>

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

// the starting eventNumber for "true" mouse events (created in our tests)
//
// NSSystemDefined events (also created in our tests) will have an event number
// below this
static const NSInteger trueMouseEventNumberMinimum = 1000;

@interface DeduplicationTestRecognizer : VELEventRecognizer
/**
 * A mask for events that this recognizer should accept.
 *
 * Once the recognizer receives an event matching this mask, that bit in the
 * mask is cleared (such that another event of the same type will fail).
 */
@property (nonatomic, assign) NSUInteger expectedEventMask;
@end

@interface PreventionTestRecognizer : VELEventRecognizer
/**
 * The last event that was passed to <handleEvent:> for this recognizer.
 */
@property (nonatomic, retain) NSEvent *lastEvent;
@end

@interface NSEvent (SystemDefinedEventCreation)
+ (NSEvent *)systemDefinedMouseEventAtLocation:(CGPoint)location mouseButtonStateMask:(NSUInteger)buttonStateMask mouseButtonStateChangedMask:(NSUInteger)buttonStateChangedMask;

+ (void)stopEventLoop;
@end

// used so that events will always be received even though the test window is
// not truly key and active
@interface AlwaysKeyVELWindow : VELWindow
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
    });

    describe(@"event handling", ^{
        __block VELWindow *window;

        __block NSEvent *leftMouseDownEvent;
        __block NSEvent *rightMouseUpEvent;
        __block NSEvent *systemDefinedEvent;

        void (^runEventLoop)(void) = ^{
            [NSEvent performSelector:@selector(stopEventLoop) withObject:nil afterDelay:0.1];
            [[NSApplication sharedApplication] run];
        };

        before(^{
            window = [[AlwaysKeyVELWindow alloc] initWithContentRect:NSMakeRect(101, 223, 500, 1000)];
            expect(window).not.toBeNil();

            [window makeKeyAndOrderFront:nil];

            __block NSInteger eventNumber = trueMouseEventNumberMinimum;

            CGPoint location = CGPointMake(215, 657);

            systemDefinedEvent = [NSEvent
                systemDefinedMouseEventAtLocation:location
                mouseButtonStateMask:BUTTON_MASK_FOR_BUTTONS(0)
                mouseButtonStateChangedMask:BUTTON_MASK_FOR_BUTTONS(0, 1)
            ];

            NSEvent *(^mouseEventAtWindowLocation)(NSEventType, CGPoint) = ^(NSEventType type, CGPoint point){
                CGRect locationRect = CGRectMake(location.x, location.y, 1, 1);
                CGRect windowRect = [window convertRectFromScreen:locationRect];

                return [NSEvent
                    mouseEventWithType:type
                    location:windowRect.origin
                    modifierFlags:systemDefinedEvent.modifierFlags
                    timestamp:systemDefinedEvent.timestamp
                    windowNumber:window.windowNumber
                    context:window.graphicsContext
                    eventNumber:eventNumber++
                    clickCount:1
                    pressure:1
                ];
            };

            leftMouseDownEvent = mouseEventAtWindowLocation(NSLeftMouseDown, location);
            rightMouseUpEvent = mouseEventAtWindowLocation(NSRightMouseUp, location);
        });

        describe(@"deduplicating system-defined events", ^{
            __block DeduplicationTestRecognizer *recognizer;

            before(^{
                recognizer = [[DeduplicationTestRecognizer alloc] init];
                expect(recognizer).not.toBeNil();

                recognizer.view = window.rootView;

                recognizer.expectedEventMask = NSLeftMouseDownMask | NSRightMouseUpMask;
            });

            after(^{
                runEventLoop();

                // the recognizer should not be expecting any further events
                expect(recognizer.expectedEventMask).toEqual(0);

                recognizer = nil;
            });

            it(@"should deduplicate an NSSystemDefined event arriving after mouse events", ^{
                [NSApp postEvent:leftMouseDownEvent atStart:NO];
                [NSApp postEvent:rightMouseUpEvent atStart:NO];
                [NSApp postEvent:systemDefinedEvent atStart:NO];
            });

            it(@"should deduplicate an NSSystemDefined event queued before mouse events", ^{
                [NSApp postEvent:systemDefinedEvent atStart:NO];
                [NSApp postEvent:leftMouseDownEvent atStart:NO];
                [NSApp postEvent:rightMouseUpEvent atStart:NO];
            });

            it(@"should deduplicate an NSSystemDefined event arriving in-between mouse events", ^{
                [NSApp postEvent:leftMouseDownEvent atStart:NO];
                [NSApp postEvent:systemDefinedEvent atStart:NO];
                [NSApp postEvent:rightMouseUpEvent atStart:NO];
            });
        });

        describe(@"event prevention", ^{
            __block PreventionTestRecognizer *firstRecognizer;
            __block PreventionTestRecognizer *secondRecognizer;
            __block PreventionTestRecognizer *thirdRecognizer;

            __block __weak PreventionTestRecognizer *weakFirstRecognizer;
            __block __weak PreventionTestRecognizer *weakSecondRecognizer;

            before(^{
                VELView *innerView = [[VELView alloc] initWithFrame:window.rootView.bounds];
                [window.rootView addSubview:innerView];

                [window makeKeyAndOrderFront:nil];

                firstRecognizer = [[PreventionTestRecognizer alloc] init];
                expect(firstRecognizer).not.toBeNil();
                firstRecognizer.view = window.rootView;

                secondRecognizer = [[PreventionTestRecognizer alloc] init];
                expect(secondRecognizer).not.toBeNil();
                secondRecognizer.view = innerView;

                thirdRecognizer = [[PreventionTestRecognizer alloc] init];
                expect(thirdRecognizer).not.toBeNil();
                thirdRecognizer.view = innerView;

                weakFirstRecognizer = firstRecognizer;
                weakSecondRecognizer = secondRecognizer;
            });

            after(^{
                firstRecognizer = nil;
                secondRecognizer = nil;
                thirdRecognizer = nil;
            });

            it(@"should happen at the point of delivery", ^{
                __block BOOL shouldPreventRecognizerCalledAfterHandlingEvent = NO;

                firstRecognizer.shouldPreventEventRecognizerBlock = ^ BOOL (VELEventRecognizer *recognizer, NSEvent *event) {
                    if (recognizer == weakSecondRecognizer && [event isEqual:weakFirstRecognizer.lastEvent]) {
                        shouldPreventRecognizerCalledAfterHandlingEvent = YES;
                        return YES;
                    }

                    return NO;
                };

                [NSApp postEvent:leftMouseDownEvent atStart:NO];

                runEventLoop();

                expect(shouldPreventRecognizerCalledAfterHandlingEvent).toBeTruthy();
                expect(firstRecognizer.lastEvent).not.toBeNil();
                expect(secondRecognizer.lastEvent).toBeNil();
            });

            it(@"should happen at the point of delivery", ^{
                __block BOOL shouldBePreventedCalledAfterHandlingEvent = NO;

                secondRecognizer.shouldBePreventedByEventRecognizerBlock = ^ BOOL (VELEventRecognizer *recognizer, NSEvent *event) {
                    if (recognizer == weakFirstRecognizer && [event isEqual:weakFirstRecognizer.lastEvent]) {
                        shouldBePreventedCalledAfterHandlingEvent = YES;
                        return YES;
                    }

                    return NO;
                };

                [NSApp postEvent:leftMouseDownEvent atStart:NO];

                runEventLoop();

                expect(shouldBePreventedCalledAfterHandlingEvent).toBeTruthy();
                expect(firstRecognizer.lastEvent).not.toBeNil();
                expect(secondRecognizer.lastEvent).toBeNil();
            });

            it(@"prevented recognizers should not prevent others", ^{
                firstRecognizer.shouldPreventEventRecognizerBlock = ^ BOOL (VELEventRecognizer *recognizer, NSEvent *event) {
                    return (recognizer == weakSecondRecognizer);
                };

                secondRecognizer.shouldPreventEventRecognizerBlock = ^ BOOL (VELEventRecognizer *recognizer, NSEvent *event) {
                    expect(recognizer).not.toEqual(thirdRecognizer);
                    return (recognizer == thirdRecognizer);
                };

                [NSApp postEvent:leftMouseDownEvent atStart:NO];

                runEventLoop();

                expect(firstRecognizer.lastEvent).not.toBeNil();
                expect(secondRecognizer.lastEvent).toBeNil();
                expect(thirdRecognizer.lastEvent).not.toBeNil();
            });
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

+ (void)stopEventLoop; {
    [NSApp stop:nil];

    NSEvent *event = [NSEvent
        otherEventWithType: NSApplicationDefined
        location:CGPointZero
        modifierFlags:0
        timestamp:0.0
        windowNumber:0
        context:nil
        subtype:0
        data1:0
        data2:0
    ];

    [NSApp postEvent:event atStart:YES];
}
@end

@implementation DeduplicationTestRecognizer
@synthesize expectedEventMask = m_expectedEventMask;

- (BOOL)handleEvent:(NSEvent *)event {
    @try {
        // this should not be a converted NSSystemDefined event
        expect(event.eventNumber).toBeGreaterThanOrEqualTo(trueMouseEventNumberMinimum);

        NSUInteger eventMask = NSEventMaskFromType(event.type);
        expect(self.expectedEventMask & eventMask).toEqual(eventMask);

        [super handleEvent:event];

        // remove this event's mask
        self.expectedEventMask &= (~eventMask);
    } @catch (NSException *ex) {
        // manually abort from exceptions, since AppKit likes to catch them
        NSLog(@"Exception thrown: %@", ex);
        abort();
    }

    // don't consume or actually "accept" any events -- we just want to test
    // event deduplication
    return NO;
}

@end

@implementation AlwaysKeyVELWindow
- (BOOL)isKeyWindow {
    return YES;
}
@end

@implementation PreventionTestRecognizer
@synthesize lastEvent = m_lastEvent;

- (BOOL)handleEvent:(NSEvent *)event {
    self.lastEvent = event;
    return [super handleEvent:event];
}

@end
