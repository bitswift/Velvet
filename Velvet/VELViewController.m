//
//  VELViewController.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 21.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "VELViewController.h"
#import "VELHostView.h"
#import "VELView.h"
#import "VELViewPrivate.h"
#import "NSWindow+ResponderChainAdditions.h"

@interface VELViewController ()
@property (nonatomic, strong, readwrite) VELView *view;

/**
 * Returns the next <VELView> that is an ancestor of <bridgedView> (or
 * <bridgedView> itself). Returns `nil` if no Velvet hierarchies exist at or
 * above the given view.
 *
 * This will also traverse any host views, to find Velvet hierarchies even
 * across bridging boundaries.
 *
 * @param bridgedView The view to return a <VELView> ancestor of. If this view
 * is a <VELView>, it is returned.
 */
- (VELView *)ancestorVELViewOfBridgedView:(id<VELBridgedView>)bridgedView;

/**
 * Action triggered when the `VELNSWindowFirstResponderDidChangeNotification`
 * is fired.
 *
 * Sets <focused> when the new first responder is one of the 
 * receiver's descendant views.
 *
 * @param notification A notification posted when the window's
 * first responder changes.
 */
- (void)firstResponderDidChange:(NSNotification *)notification;

@end

@implementation VELViewController

#pragma mark Properties

@synthesize view = m_view;
@synthesize focused = m_focused;

- (void)setFocused:(BOOL)focused {
    m_focused = focused;

    self.view.focused = focused;
}

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
}

- (VELViewController *)parentViewController {
    if (![self isViewLoaded])
        return nil;

    VELView *view = self.view;

    do {
        // traverse superviews until we reach a root view, then keep trying on
        // any Velvet hierarchies above its hostView
        view = [self ancestorVELViewOfBridgedView:view.immediateParentView];

        if (view.viewController)
            return view.viewController;
    } while (view);

    return nil;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Presentation

- (void)viewWillAppear; {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(firstResponderDidChange:)
        name:VELNSWindowFirstResponderDidChangeNotification
        object:nil
    ];
}

- (void)viewDidAppear; {
}

- (void)viewWillDisappear; {
    [[NSNotificationCenter defaultCenter]
        removeObserver:self
        name:VELNSWindowFirstResponderDidChangeNotification
        object:nil
    ];
}

- (void)viewDidDisappear; {
}

- (void)firstResponderDidChange:(NSNotification *)notification {
    id responder = [[notification userInfo] objectForKey:VELNSWindowNewFirstResponderKey];

    while (responder && ![responder conformsToProtocol:@protocol(VELBridgedView)])
        responder = [responder nextResponder];

    while (responder) {
        if (responder == self.view) {
            self.parentViewController.focused = NO;
            self.focused = YES;
            return;
        }
        
        responder = [responder immediateParentView];
    }
    
    self.focused = NO;
}

#pragma mark Responder chain

- (BOOL)acceptsFirstResponder {
    return YES;
}

#pragma mark View hierarchy

- (VELView *)ancestorVELViewOfBridgedView:(id<VELBridgedView>)bridgedView; {
    if (!bridgedView)
        return nil;

    if ([bridgedView isKindOfClass:[VELView class]])
        return (id)bridgedView;

    // we don't need to check bridgedView.superview, since we already know it's
    // not in a Velvet hierarchy
    return [self ancestorVELViewOfBridgedView:bridgedView.hostView];
}

@end
