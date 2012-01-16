//
//  VELWindow.m
//  Velvet
//
//  Created by Bryan Hansen on 11/21/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELWindow.h>
#import <Velvet/NSVelvetView.h>
#import <Proton/Proton.h>

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

#pragma mark Lifecycle

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
    self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation];
    if (!self)
        return nil;

    self.contentView = [[NSVelvetView alloc] init];
    return self;
}

@end
