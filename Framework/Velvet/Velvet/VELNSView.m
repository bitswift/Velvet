//
//  VELNSView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 20.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELNSView.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <Velvet/NSVelvetView.h>
#import <Velvet/VELContext.h>
#import <Velvet/VELViewPrivate.h>

@implementation VELNSView

#pragma mark Properties

@synthesize NSView = m_NSView;

- (NSView *)NSView {
    __block NSView *view;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        view = m_NSView;
    });

    return view;
}

- (void)setNSView:(NSView *)view {
    // set up layer-backing on the view, so it will render into its layer as
    // soon as possible (without tying up the dispatch queue, if possible)
    [view setWantsLayer:YES];
    [view setNeedsDisplay:YES];

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        view.frame = [self.superview convertRect:self.frame toView:self.hostView.rootView];

        [self.hostView addSubview:view];
        m_NSView = view;
    });
}

#pragma mark Lifecycle

- (id)initWithNSView:(NSView *)view; {
    self = [self init];
    if (!self)
        return nil;

    self.NSView = view;
    return self;
}

@end
