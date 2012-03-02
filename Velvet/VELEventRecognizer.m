//
//  VELEventRecognizer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELEventRecognizer.h"

@implementation VELEventRecognizer

#pragma mark Properties

// TODO
@dynamic view;
@dynamic state;
@dynamic active;
@dynamic enabled;
@dynamic continuous;
@dynamic discrete;
@dynamic recognizersRequiredToFail;
@dynamic delaysEventDelivery;

#pragma mark States and Transitions

- (void)reset; {
    // TODO
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
