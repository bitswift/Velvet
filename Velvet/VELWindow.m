//
//  VELWindow.m
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELWindow.h"
#import "NSVelvetView.h"

@class NSVelvetHostView;

NSString * const VELWindowFirstResponderDidChangeNotification = @"VELWindowFirstResponderDidChangeNotification";

NSString * const VELWindowOldFirstResponderKey = @"VELWindowOldFirstResponderKey";

NSString * const VELWindowNewFirstResponderKey = @"VELWindowNewFirstResponderKey";

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

#pragma mark First Responder

- (BOOL)makeFirstResponder:(NSResponder *)responder {
    id previousResponder = self.firstResponder ?: [NSNull null];

    BOOL success = [super makeFirstResponder:responder];
    if (!success)
        return NO;

    id newResponder = self.firstResponder ?: [NSNull null];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        previousResponder, VELWindowOldFirstResponderKey,
        newResponder, VELWindowNewFirstResponderKey,
        nil
    ];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:VELWindowFirstResponderDidChangeNotification
        object:self
        userInfo:userInfo
    ];

    return success;
}

@end
