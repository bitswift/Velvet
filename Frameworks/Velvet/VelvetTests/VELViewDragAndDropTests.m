//
//  VELViewDragAndDropTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 10.01.12.
//  Copyright (c) 2012 Emerald Lark. All rights reserved.
//

#import "VELViewDragAndDropTests.h"
#import <Velvet/Velvet.h>
#import <Cocoa/Cocoa.h>

@interface DragDestinationView : VELView <VELDraggingDestination>
@end

@implementation VELViewDragAndDropTests

- (void)testAutomaticRegistration {
    NSVelvetView *hostView = [[NSVelvetView alloc] initWithFrame:CGRectZero];
    STAssertEquals([hostView.registeredDraggedTypes count], (NSUInteger)0, @"");

    DragDestinationView *dragDestination = [[DragDestinationView alloc] init];
    [hostView.rootView addSubview:dragDestination];

    STAssertEqualObjects(hostView.registeredDraggedTypes, dragDestination.supportedDragTypes, @"");

    [dragDestination removeFromSuperview];
    STAssertEquals([hostView.registeredDraggedTypes count], (NSUInteger)0, @"");
}

@end

@implementation DragDestinationView
- (NSArray *)supportedDragTypes; {
    return [NSArray arrayWithObjects:NSPasteboardTypeString, NSPasteboardTypeTIFF, nil];
}
@end
