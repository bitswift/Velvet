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
#import "VELDraggingDestinationView.h"

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSVelvetView *hostView;

@property (strong) VELView *rootView;
@property (strong) VELScrollView *scrollView;
@property (strong) SquareView *nestedSquareView;
@property (strong) VELNSView *buttonHost;

@property (nonatomic, strong) NSArray *views;

- (void)hierarchyTests;
- (void)animateMe;

- (void)draggingTests;
- (void)createViews;
- (void)animateViews;
- (void)scalingTests;
@end

@implementation AppDelegate
@synthesize window = m_window;
@synthesize hostView = m_hostView;
@synthesize rootView = m_rootView;
@synthesize scrollView = m_scrollView;
@synthesize nestedSquareView = m_nestedSquareView;
@synthesize buttonHost = m_buttonHost;
@synthesize views = m_views;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification; {
#if 0
    [self createViews];
    [self performSelector:@selector(animateViews) withObject:nil afterDelay:2.0];
#else
//    [self draggingTests];
//    [self scalingTests];
    [self hierarchyTests];
#endif
}

- (void)scalingTests {
    VELView *containerView = [[VELView alloc] init];
    containerView.layer.backgroundColor = CGColorGetConstantColor(kCGColorWhite);
    containerView.frame = CGRectMake(100,100,100,100);



    VELNSView *backgroundView = [[VELNSView alloc] init];
    backgroundView.frame = CGRectMake(5,5, 50,50);
    CGColorRef redColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    backgroundView.layer.backgroundColor = redColor;
    CGColorRelease(redColor);


    [self.hostView.rootView addSubview:containerView];
    [containerView addSubview:backgroundView];


    NSTextField *scalingView = [[NSTextField alloc] init];
    [backgroundView setNSView:scalingView];
    [scalingView setBezelStyle:NSTextFieldSquareBezel];

    
    int64_t delayInSeconds = (int64_t)2.0;

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [CATransaction begin];
        [CATransaction setAnimationDuration:2.0];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
        const CGFloat scale = 3.0f;
        containerView.layer.transform = CATransform3DScale(containerView.layer.transform, scale, scale, scale);
        [CATransaction commit];
    });
}


- (void)draggingTests {
    NSButton *backgroundButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    [backgroundButton setButtonType:NSMomentaryPushInButton];
    [backgroundButton setBezelStyle:NSRoundedBezelStyle];
    [backgroundButton setTitle:@"Test Button"];
    [backgroundButton setTarget:self];
    [backgroundButton setAction:@selector(testButtonPushed:)];


    VELNSView *backgroundVELView = [[VELNSView alloc] initWithNSView:backgroundButton];
    backgroundVELView.layer.masksToBounds = YES;
    backgroundVELView.frame = CGRectMake(80, 80, 200, 200);

    VELDraggingDestinationView *view1 = [[VELDraggingDestinationView alloc] init];
    view1.frame = CGRectMake(10, 10, 200, 200);
    view1.name = @"outer";

    VELDraggingDestinationView *view2 = [[VELDraggingDestinationView alloc] init];
    view2.frame = CGRectMake(50, 50, 50, 50);
    view2.name = @"inner";

    [view1 addSubview:view2];

    [self.hostView.rootView addSubview:view1];
    [view1 addSubview:backgroundVELView];
}

- (void)hierarchyTests {
    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"iceberg" withExtension:@"jpg"];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageURL];
    NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);

    self.scrollView = [[VELScrollView alloc] init];
    self.scrollView.layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
    self.scrollView.contentSize = imageRect.size;
    self.scrollView.frame = CGRectMake(20, 20, 300, 300);

    VELView *scrollableSquareView = [[SquareView alloc] init];
    scrollableSquareView.frame = CGRectMake(20, 200, 800, 800);

    VELImageView *imageView = [[VELImageView alloc] init];
    imageView.frame = imageRect;
    imageView.image = [image CGImageForProposedRect:NULL context:nil hints:nil];

    self.scrollView.subviews = [self.scrollView.subviews arrayByAddingObject:scrollableSquareView];
    self.scrollView.subviews = [self.scrollView.subviews arrayByAddingObject:imageView];

    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 150, 91, 22)];
    [textField.cell setUsesSingleLineMode:YES];
    [textField.cell setScrollable:YES];
    [textField setBackgroundColor:[NSColor whiteColor]];
    [textField setDrawsBackground:YES];

    VELView *rootSquareView = [[SquareView alloc] init];
    rootSquareView.frame = CGRectMake(20, 20, 300, 300);
    imageView.subviews = [NSArray arrayWithObject:rootSquareView];

    VELNSView *textFieldHost = [[VELNSView alloc] initWithNSView:textField];
    imageView.subviews = [imageView.subviews arrayByAddingObject:textFieldHost];

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                (__bridge_transfer id)CGColorCreateGenericGray(0, 1), (__bridge id)kCTForegroundColorAttributeName,
                                (__bridge_transfer id)CTFontCreateUIFontForLanguage(kCTFontSystemFontType, 16, NULL), (__bridge id)kCTFontAttributeName,
                                nil
                                ];

    VELLabel *label = [[VELLabel alloc] init];
    label.text = [[NSAttributedString alloc] initWithString:@"** Hello world! **" attributes:attributes];
    label.frame = CGRectMake(0, 400, 300, 60);

    self.hostView.rootView.subviews = [NSArray arrayWithObjects:label, self.scrollView, nil];

    self.nestedSquareView = [[SquareView alloc] init];
    self.nestedSquareView.layer.masksToBounds = YES;
    self.nestedSquareView.frame = CGRectMake(0, 0, 80, 80);

    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 80, 28)];
    [button setButtonType:NSMomentaryPushInButton];
    [button setBezelStyle:NSRoundedBezelStyle];
    [button setTitle:@"Test Button"];
    [button setTarget:self];
    [button setAction:@selector(testButtonPushed:)];

    self.buttonHost = [[VELNSView alloc] init];
    self.buttonHost.layer.masksToBounds = YES;
    self.buttonHost.layer.backgroundColor = CGColorGetConstantColor(kCGColorWhite);
    self.buttonHost.frame = CGRectMake(30, 30, button.frame.size.width, button.frame.size.height);

    rootSquareView.subviews = [NSArray arrayWithObject:self.nestedSquareView];
    self.nestedSquareView.subviews = [NSArray arrayWithObject:self.buttonHost];
    self.buttonHost.NSView = button;

    //    [self performSelector:@selector(animateMe) withObject:nil afterDelay:1.0];
}

- (void)updateScrollers {
    self.scrollView.horizontalScroller.doubleValue = 0.2;
}

- (void)animateMe
{
    [CATransaction begin];
    [CATransaction setAnimationDuration:2.0];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];

    CGRect frm = self.scrollView.frame;
    frm.origin.x += 150;
    frm.origin.y += 20;
//  frm.size.height /= 2.0;
    self.scrollView.frame = frm;

    CGRect frm2 = self.buttonHost.frame;
    frm2.origin.x += 150;
    frm2.origin.y += 20;
//  frm.size.height /= 2.0;
    self.buttonHost.frame = frm2;

    [CATransaction commit];
}

- (void)testButtonPushed:(id)sender {
    NSLog(@"testButtonPushed");
}


- (NSImage *)loadLolz {
    NSImage *image = [NSImage imageNamed:@"lolcats.jpg"];
    return image;
}

- (void)createViews {
    const NSUInteger numViews = 900;
    const NSUInteger numCols = 30;

    NSMutableArray *views = [NSMutableArray arrayWithCapacity:numViews];

    NSImage *image = [self loadLolz];
    CGImageRef imageRef = [image CGImageForProposedRect:NULL context:nil hints:nil];

    for (NSUInteger i = 0; i < numViews; ++i) {
        VELImageView *v = [[VELImageView alloc] init];
        v.image = imageRef;
        v.frame = NSMakeRect((i % numCols) * 60, (i / numCols) * 60, 50, 50);
        [views addObject:v];
    }

    self.hostView.rootView.subviews = views;
    self.views = views;
}

- (void)animateViews {

    id completionBlock = ^ {
        [self performSelector:_cmd withObject:nil afterDelay:0.2];
    };

    void (^animationBlock)(void) = ^{
        [CATransaction begin];
        [CATransaction setCompletionBlock:completionBlock];

        for (NSUInteger i = 0; i < self.views.count / 2; ++i) {
            VELView *v = [self.views objectAtIndex:i];
            NSUInteger j = self.views.count - i - 1; // RandomInRange(i, self.views.count);
            VELView *w = [self.views objectAtIndex:j];

            CGPoint vPos = v.layer.position;
            CGPoint wPos = w.layer.position;

            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
//            animation.isRemovedOnCompletion = NO;
            animation.fromValue = [NSValue valueWithPoint:vPos];
            animation.toValue = [NSValue valueWithPoint:wPos];
            animation.duration = 1;
            [v.layer addAnimation:animation forKey:@"posAnim"];

            CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"position"];
//            animation2.isRemovedOnCompletion = NO;
            animation2.fromValue = [NSValue valueWithPoint:wPos];
            animation2.toValue = [NSValue valueWithPoint:vPos];
            animation2.duration = 1;
            [w.layer addAnimation:animation2 forKey:@"posAnim"];
        }

        [CATransaction commit];
    };

    animationBlock();

    //[NSAnimationContext runAnimationGroup:animationBlock completionHandler:completionBlock];
}

@end

