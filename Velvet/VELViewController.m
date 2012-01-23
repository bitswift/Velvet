//
//  VELViewController.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 21.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELViewController.h"
#import "VELView.h"
#import "VELViewPrivate.h"

@interface VELViewController ()
@property (nonatomic, strong, readwrite) VELView *view;
@end

@implementation VELViewController

#pragma mark Properties

@synthesize view = m_view;

- (BOOL)isViewLoaded {
    return m_view != nil;
}

- (VELView *)view {
    if (!self.viewLoaded) {
        self.view = [self loadView];
    }

    return m_view;
}

- (void)setView:(VELView *)view {
    if (view == m_view)
        return;

    view.viewController = self;

    if (!m_view) {
        m_view = view;
        return;
    }

    [m_view removeFromSuperview];

    if (!view)
        [self viewWillUnload];

    m_view = view;

    if (!view)
        [self viewDidUnload];

    [self invalidateRestorableState];
}

#pragma mark Lifecycle

- (VELView *)loadView; {
    return [[VELView alloc] init];
}

- (void)viewDidUnload; {
}

- (void)viewWillUnload; {
}

- (void)dealloc {
    // remove 'self' as the next responder
    if (m_view.nextResponder == self)
        m_view.nextResponder = nil;

    // make sure to always call -viewWillUnload and -viewDidUnload
    self.view = nil;

    [self.undoManager removeAllActionsWithTarget:self];
}

#pragma mark Presentation

- (void)viewWillAppear; {
}

- (void)viewDidAppear; {
}

- (void)viewWillDisappear; {
}

- (void)viewDidDisappear; {
}

#pragma mark Responder chain

- (BOOL)acceptsFirstResponder {
    return YES;
}

@end
