//
//  AppDelegate.m
//  VelvetDemo
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "AppDelegate.h"
#import <Velvet/Velvet.h>

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet VELNSView *hostView;

@property (weak) VELView *rootView;
@end

@implementation AppDelegate
@synthesize window = m_window;
@synthesize hostView = m_hostView;
@synthesize rootView = m_rootView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification; {
}

@end
