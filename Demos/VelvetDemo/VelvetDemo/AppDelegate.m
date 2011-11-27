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
#import <QuartzCore/QuartzCore.h>

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSVelvetView *hostView;

@property (strong) VELView *rootView;
@property (strong) VELNSView *scrollViewHost;
@property (strong) SquareView *nestedSquareView;
@property (strong) VELNSView *buttonHost;

- (void)animateMe;
@end

@implementation AppDelegate
@synthesize window = m_window;
@synthesize hostView = m_hostView;
@synthesize rootView = m_rootView;
@synthesize scrollViewHost = m_scrollViewHost;
@synthesize nestedSquareView = m_nestedSquareView;
@synthesize buttonHost = m_buttonHost;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification; {
    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"iceberg" withExtension:@"jpg"];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageURL];

    NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:imageRect];
    [imageView setBounds:imageRect];
    [imageView setImage:image];

    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 150, 91, 22)];
    [textField.cell setUsesSingleLineMode:YES];
    [textField.cell setScrollable:YES];
    [textField setBackgroundColor:[NSColor whiteColor]];
    [textField setDrawsBackground:YES];
    [imageView addSubview:textField];

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 20, 300, 300)];
    [scrollView setBorderType:NSNoBorder];
    [scrollView setDocumentView:imageView];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setDrawsBackground:NO];
    [scrollView setUsesPredominantAxisScrolling:NO];

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge_transfer id)CGColorCreateGenericGray(0, 1), (__bridge id)kCTForegroundColorAttributeName,
        (__bridge_transfer id)CTFontCreateUIFontForLanguage(kCTFontSystemFontType, 16, NULL), (__bridge id)kCTFontAttributeName,
        nil
    ];

    VELLabel *label = [[VELLabel alloc] init];
    label.text = [[NSAttributedString alloc] initWithString:@"** Hello world! **" attributes:attributes];
    label.frame = CGRectMake(0, 400, 300, 60);
    self.hostView.rootView.subviews = [NSArray arrayWithObject:label];

    self.scrollViewHost = [[VELNSView alloc] init];
    self.scrollViewHost.frame = scrollView.frame;

    self.hostView.rootView.subviews = [self.hostView.rootView.subviews arrayByAddingObject:self.scrollViewHost];
    self.scrollViewHost.NSView = scrollView;

    VELView *rootSquareView = [[VELView alloc] init];
    rootSquareView.frame = CGRectMake(0, 0, 200, 200);

    self.nestedSquareView = [[SquareView alloc] init];
    self.nestedSquareView.layer.masksToBounds = YES;
    self.nestedSquareView.frame = CGRectMake(0, 0, 80, 80);

    NSVelvetView *nestedVelvetView = [[NSVelvetView alloc] initWithFrame:NSMakeRect(20, 20, 300, 300)];
    nestedVelvetView.layer.masksToBounds = YES;
    nestedVelvetView.rootView = rootSquareView;
    [imageView addSubview:nestedVelvetView];

    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 80, 28)];
    [button setButtonType:NSMomentaryPushInButton];
    [button setBezelStyle:NSRoundedBezelStyle];
    [button setTitle:@"Test Button"];
    [button setTarget:self];
    [button setAction:@selector(buttonClicked)];

    self.buttonHost = [[VELNSView alloc] init];
    self.buttonHost.layer.masksToBounds = YES;
    self.buttonHost.layer.backgroundColor = CGColorGetConstantColor(kCGColorWhite);
    self.buttonHost.frame = CGRectMake(30, 30, button.frame.size.width, button.frame.size.height);

    rootSquareView.subviews = [NSArray arrayWithObject:self.nestedSquareView];
    self.nestedSquareView.subviews = [NSArray arrayWithObject:self.buttonHost];
    self.buttonHost.NSView = button;

    // [self performSelector:@selector(animateMe) withObject:nil afterDelay:1.0];
}

- (void)buttonClicked
{
    NSLog(@"CLICKED");
}

- (void)animateMe
{
    [CATransaction begin];
    [CATransaction setAnimationDuration:2.0];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];

    CGRect frm = self.scrollViewHost.frame;
    frm.origin.x += 150;
    frm.origin.y += 20;
//  frm.size.height /= 2.0;
    self.scrollViewHost.frame = frm;

    CGRect frm2 = self.buttonHost.frame;
    frm2.origin.x += 150;
    frm2.origin.y += 20;
//  frm.size.height /= 2.0;
    self.buttonHost.frame = frm2;

    [CATransaction commit];
}

@end

