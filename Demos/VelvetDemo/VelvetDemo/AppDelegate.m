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
@property (strong) VELNSView *scrollViewHost;
@end

@implementation AppDelegate
@synthesize window = m_window;
@synthesize hostView = m_hostView;
@synthesize rootView = m_rootView;
@synthesize scrollViewHost = m_scrollViewHost;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification; {
	NSRect windowRect = [self.window contentRectForFrameRect:self.window.frame];
	CGSize windowSize = windowRect.size;

	self.rootView = [[SquareView alloc] init];
	self.rootView.frame = CGRectMake(0, 0, windowSize.width, windowSize.height);
	self.hostView.rootView = self.rootView;
	
	NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"iceberg" withExtension:@"jpg"];
	NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageURL];

	NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
	NSImageView *imageView = [[NSImageView alloc] initWithFrame:imageRect];
	[imageView setBounds:imageRect];
	[imageView setImage:image];

	NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 20, 300, 300)];
	[scrollView setBorderType:NSNoBorder];
	[scrollView setDocumentView:imageView];
	[scrollView setHasHorizontalScroller:YES];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setDrawsBackground:NO];
	[scrollView setUsesPredominantAxisScrolling:NO];

	self.scrollViewHost = [[VELNSView alloc] init];
	self.scrollViewHost.frame = scrollView.frame;

	self.rootView.subviews = [NSArray arrayWithObject:self.scrollViewHost];
	self.scrollViewHost.NSView = scrollView;

	SquareView *nestedSquareView = [[SquareView alloc] init];
	nestedSquareView.frame = CGRectMake(0, 0, 80, 80);

	NSVelvetView *nestedVelvetView = [[NSVelvetView alloc] initWithFrame:NSMakeRect(20, 20, 80, 80)];
	nestedVelvetView.rootView = nestedSquareView;
	[imageView addSubview:nestedVelvetView];

	NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 80, 20)];
	[button setButtonType:NSMomentaryPushInButton];
	[button setBezelStyle:NSRoundedBezelStyle];
	[button setTitle:@"Test Button"];

	VELNSView *buttonHost = [[VELNSView alloc] init];
	buttonHost.frame = button.frame;

	nestedSquareView.subviews = [NSArray arrayWithObject:buttonHost];
	buttonHost.NSView = button;
}

@end
