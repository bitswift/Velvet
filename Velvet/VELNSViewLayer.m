//
//  VELNSViewLayer.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 23.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELNSViewLayer.h"
#import "VELNSViewPrivate.h"

@implementation VELNSViewLayer

#pragma mark Properties

// implemented by VELViewLayer
@dynamic view;

#pragma mark Drawing

- (void)display {
    // don't cache any layer contents if the VELNSView isn't rendering its
    // NSView
    if (!self.view.renderingContainedView) {
        self.contents = nil;
        return;
    }

    [super display];
}

@end
