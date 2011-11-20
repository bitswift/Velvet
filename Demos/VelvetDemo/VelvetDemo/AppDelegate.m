//
//  AppDelegate.m
//  VelvetDemo
//
//  Created by Justin Spahr-Summers on 19.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "AppDelegate.h"
#import "SquareView.h"
#import <Velvet/Velvet.h>

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSVelvetView *hostView;

@property (strong) VELView *rootView;
@end

@implementation AppDelegate
@synthesize window = m_window;
@synthesize hostView = m_hostView;
@synthesize rootView = m_rootView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification; {
	self.rootView = [[SquareView alloc] init];
	self.rootView.frame = CGRectMake(20, 20, 200, 200);
	self.hostView.rootView = self.rootView;

	NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 80, 20)];
	[button setButtonType:NSMomentaryPushInButton];
	[button setBezelStyle:NSRoundedBezelStyle];
	[button setTitle:@"Test Vanilla Button"];
	[self.hostView addSubview:button];
}

@end
