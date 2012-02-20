//
//  VELNSViewController.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.02.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELNSViewController.h"

@interface VELNSViewController ()
@property (nonatomic, strong, readwrite) IBOutlet NSView *guestView;
@end

@implementation VELNSViewController

#pragma mark Properties

// implemented by VELViewController
@dynamic view;

@synthesize guestView;

- (NSString *)nibName {
    return nil;
}

- (NSBundle *)nibBundle {
    return [NSBundle bundleForClass:self.class];
}

#pragma mark View Loading

- (VELNSView *)loadView; {
    if (self.nibName) {
        NSNib *nib = [[NSNib alloc] initWithNibNamed:self.nibName bundle:self.nibBundle];
        if ([nib instantiateNibWithOwner:self topLevelObjects:nil]) {
            return [[VELNSView alloc] initWithNSView:self.guestView];
        }
    }

    self.guestView = [[NSView alloc] initWithFrame:CGRectZero];
    return [[VELNSView alloc] initWithNSView:self.guestView];
}

#pragma mark Nib Loading

- (void)awakeFromNib; {
}

@end
