//
//  ADAppDelegate.m
//  AppKitAnimationDemo
//
//  Created by James Lawton on 11/28/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "ADAppDelegate.h"
#import "ADDraggingDestinationView.h"


@interface ADAppDelegate ()
@property (nonatomic, strong) NSArray *views;
- (void)createViews;
- (void)animateViews;
@end


NSUInteger RandomInRange(NSUInteger min, NSUInteger max);

@implementation ADAppDelegate

@synthesize window = m_window;
@synthesize views = m_views;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    [self createViews];
//    [self performSelector:@selector(animateViews) withObject:nil afterDelay:2.0];

    ADDraggingDestinationView *view1 = [[ADDraggingDestinationView alloc] initWithFrame:CGRectZero];
    view1.frame = NSMakeRect(10, 10, 400, 400);
    view1.name = @"outer";
    view1.draggingEnabled = YES;
    
    ADDraggingDestinationView *view2 = [[ADDraggingDestinationView alloc] initWithFrame:CGRectZero];
    view2.frame = NSMakeRect(50, 50, 50, 50);
    view2.name = @"inner";
    view2.draggingEnabled = YES;
    
    [view1 addSubview:view2];
    [self.window.contentView addSubview:view1];
}

- (NSImage *)loadLolz {
    NSImage *image = [NSImage imageNamed:@"lolcats.jpg"];
    return image;
}

NSUInteger RandomInRange(NSUInteger min, NSUInteger max) {
    return (NSUInteger)floor(rand() * (max - min) / RAND_MAX + min);
}

- (void)createViews {
    const NSUInteger numViews = 900;
    const NSUInteger numCols = 30;
    
    NSMutableArray *views = [NSMutableArray arrayWithCapacity:numViews];
    
    NSImage *image = [self loadLolz];
    
    for (NSUInteger i = 0; i < numViews; ++i) {
        NSImageView *v = [[NSImageView alloc] initWithFrame:
            NSMakeRect((i % numCols) * 60, (i / numCols) * 60, 50, 50)
        ];
        v.image = image;
        [self.window.contentView addSubview:v];
        [views addObject:v];
    }
    
    self.views = views;
}

- (void)animateViews {
    
    id animationBlock = ^(NSAnimationContext *context) {
        [context setDuration:1.0];
        for (NSUInteger i = 0; i < self.views.count / 2; ++i) {
            NSView *v = [self.views objectAtIndex:i];
            NSUInteger j = self.views.count - i - 1; // RandomInRange(i, self.views.count);
            NSView *w = [self.views objectAtIndex:j];
            NSRect tmpFrame = [v.animator frame];
            [v.animator setFrame:[w.animator frame]];
            [w.animator setFrame:tmpFrame];
        }
    };
    
    id completionBlock = ^ {
        [self performSelector:_cmd withObject:nil afterDelay:0.2];
    };
    
    [NSAnimationContext runAnimationGroup:animationBlock completionHandler:completionBlock];
}

@end
