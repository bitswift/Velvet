//
//  VELWindow.m
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELWindow.h"
#import "EXTScope.h"
#import "NSVelvetView.h"
#import "NSView+VELBridgedViewAdditions.h"
#import "VELKeyPress.h"
#import "VELKeyPressEventRecognizer.h"

@class NSVelvetHostView;

@implementation VELWindow

#pragma mark Properties

// implemented by NSWindow
@dynamic contentView;

- (VELView *)rootView; {
    NSVelvetView *contentView = self.contentView;
    NSAssert([contentView isKindOfClass:[NSVelvetView class]], @"Window %@ does not have an NSVelvetView as its content view", self);

    return contentView.guestView;
}

- (void)setRootView:(VELView *)view {
    NSVelvetView *contentView = self.contentView;
    NSAssert([contentView isKindOfClass:[NSVelvetView class]], @"Window %@ does not have an NSVelvetView as its content view", self);

    contentView.guestView = view;
}

// set up slo-mo mode using an event recognizer on the content view
#ifdef DEBUG
- (void)setContentView:(NSView *)view {
    NSMutableArray *keyPresses = [NSMutableArray array];
    for (unsigned i = 0; i < 3; ++i) {
        VELKeyPress *keyPress = [[VELKeyPress alloc] initWithCharactersIgnoringModifiers:nil modifierFlags:NSShiftKeyMask];
        [keyPresses addObject:keyPress];
    }

    VELKeyPressEventRecognizer *recognizer = [[VELKeyPressEventRecognizer alloc] init];
    recognizer.view = view;
    recognizer.keyPressesToRecognize = keyPresses;

    __weak NSView *weakView = view;
    __unsafe_unretained VELWindow *weakWindow = self;
    __block BOOL slowMotionEnabled = NO;

    [recognizer addActionUsingBlock:^(VELKeyPressEventRecognizer *recognizer){
        if (!recognizer.active)
            return;

        slowMotionEnabled = !slowMotionEnabled;
        if (slowMotionEnabled) {
            NSLog(@"*** Enabling slow-motion animations for window \"%@\"", weakWindow.title);
            weakView.layer.speed = 0.1;
        } else {
            NSLog(@"*** Disabling slow-motion animations for window \"%@\"", weakWindow.title);
            weakView.layer.speed = 1;
        }
    }];

    [super setContentView:view];
}
#endif

#pragma mark Lifecycle

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
    self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation];
    if (!self)
        return nil;

    self.contentView = [[NSVelvetView alloc] init];
    self.contentView.guestView.backgroundColor = [NSColor windowBackgroundColor];
    self.contentView.opaque = YES;

    // this fixes an issue refreshing our Velvet views when returning from fast user switching
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(workspaceSessionDidBecomeActive:)
        name:NSWorkspaceSessionDidBecomeActiveNotification
        object:nil
    ];

    return self;
}

- (void)dealloc {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

#pragma mark Notifications

- (void)workspaceSessionDidBecomeActive:(NSNotification *)notification {
    // save the first responder, since resetting the hierarchy will lose it
    NSResponder *firstResponder = [self firstResponder];

    // NSWindow sucks? (magic)
    self.contentView = self.contentView;

    // reset the frame of the guestView, and re-add it as a layer
    self.contentView.guestView = self.contentView.guestView;

    [self makeFirstResponder:firstResponder];
}

@end
