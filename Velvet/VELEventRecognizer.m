//
//  VELEventRecognizer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELEventRecognizer.h"
#import "VELEventRecognizerProtected.h"

@implementation VELEventRecognizer

#pragma mark Properties

@synthesize view = m_view;
@synthesize state = m_state;
@synthesize enabled = m_enabled;
@synthesize recognizersRequiredToFail = m_recognizersRequiredToFail;
@synthesize delaysEventDelivery = m_delaysEventDelivery;

- (BOOL)isActive {
    // TODO
    return NO;
}

- (BOOL)isContinuous {
    return NO;
}

- (BOOL)isDiscrete {
    return NO;
}

#pragma mark Event Handling

- (void)handleEvent:(NSEvent *)event; {
    NSAssert(NO, @"%s must be overridden by subclasses", __func__);
}

#pragma mark States and Transitions

- (void)didTransitionFromState:(VELEventRecognizerState)fromState; {
}

- (void)reset; {
    // TODO
}

- (void)willTransitionToState:(VELEventRecognizerState)toState; {
}

#pragma mark Actions

- (id)addActionUsingBlock:(void (^)(VELEventRecognizer *))block; {
    // TODO
    return nil;
}

- (void)removeAction:(id)action; {
    // TODO
}

@end
