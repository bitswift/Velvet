//
//  NSVelvetHostView.m
//  Velvet
//
//  Created by Bryan Hansen on 11/23/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "NSVelvetHostView.h"
#import "NSVelvetView.h"

@interface NSVelvetHostView ()
/*
 * Configures all the necessary properties on the receiver. This is outside of
 * an initializer because `NSView` has no true designated initializer.
 */
- (void)setUp;
@end

@implementation NSVelvetHostView

#pragma mark Properties

- (NSVelvetView *)velvetView {
  return (NSVelvetView *)self.superview;
}

#pragma mark Lifecycle

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self)
        return nil;

    [self setUp];
    return self;
}

- (id)initWithFrame:(NSRect)frame; {
    self = [super initWithFrame:frame];
    if (!self)
        return nil;

    [self setUp];
    return self;
}

- (void)setUp; {
    // set up layer hosting for Velvet
    self.layer = [CALayer layer];
    self.wantsLayer = YES;
}

#pragma mark Rendering

- (BOOL)needsDisplay {
    // mark this view as needing display anytime the layer is
    return [super needsDisplay] || [self.layer needsDisplay];
}

#pragma mark Event Handling

- (NSView *)hitTest:(NSPoint)point {
    return nil;
}

@end
