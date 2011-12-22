//
//  VELViewController.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 21.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELViewController.h>
#import <Velvet/VELView.h>

@interface VELViewController ()
@property (nonatomic, strong, readwrite) VELView *view;
@end

@implementation VELViewController

#pragma mark Properties

@synthesize view = m_view;

- (BOOL)isViewLoaded {
    return NO;
}

#pragma mark Lifecycle

- (VELView *)loadView; {
    return nil;
}

- (void)viewDidUnload; {
}

- (void)viewWillUnload; {
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

@end
