//
//  VELControlTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 16.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELControlTests.h"
#import <Velvet/VELControl.h>
#import <Cocoa/Cocoa.h>

@interface VELControlTests ()
- (void)verifyControl:(VELControl *)control invokesActionForEvent:(VELControlEventMask)event usingBlock:(void (^)(void))block;
@end

@implementation VELControlTests

- (void)testInitialization {
    VELControl *control = [[VELControl alloc] init];
    STAssertNotNil(control, @"");

    STAssertFalse(control.selected, @"");
}

- (void)testSendActionsForControlEvents {
    VELControl *control = [[VELControl alloc] init];

    [self verifyControl:control invokesActionForEvent:VELControlEventClicked usingBlock:^{
        [control sendActionsForControlEvents:VELControlEventClicked];
    }];
}

- (void)testSendActionsForControlEventsWithNilEvent {
    VELControl *control = [[VELControl alloc] init];

    [self verifyControl:control invokesActionForEvent:VELControlEventClicked usingBlock:^{
        [control sendActionsForControlEvents:VELControlEventClicked event:nil];
    }];
}

- (void)verifyControl:(VELControl *)control invokesActionForEvent:(VELControlEventMask)event usingBlock:(void (^)(void))block {
    __block BOOL handlerInvoked = NO;
    
    id handler = [control addActionForControlEvents:event usingBlock:^(NSEvent *event){
        handlerInvoked = YES;
    }];

    STAssertNotNil(handler, @"");
    STAssertFalse(handlerInvoked, @"");

    block();
    STAssertTrue(handlerInvoked, @"");

    [control removeAction:handler forControlEvents:event];
}

@end
