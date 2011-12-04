//
//  Document.m
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 30.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "Document.h"

@implementation Document
@synthesize navBar = m_navBar;
@synthesize treeView = m_treeView;
@synthesize editorView = m_editorView;
@synthesize tempScreen = m_tempScreen;

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    return self;
}

- (NSString *)windowNibName {
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];

    VELWindow *window = (id)[aController window]; 

    self.treeView = [[TreeView alloc] init];
    self.treeView.frame = CGRectMake(0, 0, 1024, 724);
    self.treeView.autoresizingMask = VELAutoresizingFlexibleWidth | VELAutoresizingFlexibleHeight;
    [window.rootView addSubview:self.treeView];

    self.navBar = [[NavigationBar alloc] init];
    self.navBar.frame = CGRectMake(0, 724, 1024, 44);
    self.navBar.autoresizingMask = VELAutoresizingFlexibleWidth | VELAutoresizingFlexibleBottomMargin;
    [window.rootView addSubview:self.navBar];

    __weak id weakSelf = self;
    [self.navBar.openCloseButton addActionForControlEvents:VELControlEventClicked usingBlock:^{
        [weakSelf openSelectedScreen];
    }];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

#pragma mark - Actions

- (void)openSelectedScreen {
    VELWindow *window = (id)[[self.windowControllers objectAtIndex:0] window]; 
    
    self.tempScreen = [[Screen alloc] init];
    self.tempScreen.frame = [self.treeView convertRect:self.treeView.selectedScreen.frame toView:window.rootView];
    self.tempScreen.thumbnailImageView.image = self.treeView.selectedScreen.thumbnailImageView.image;

    self.treeView.selectedScreen.hidden = YES;
    [window.rootView addSubview:self.tempScreen];
    
    [VELView
        animateWithDuration:0.45f
        animations:^{
            NSRect newRect = NSMakeRect((self.treeView.frame.size.width - 320.0f) / 2.0f, (self.treeView.frame.size.height - 480.f) / 2.0f, 320.0f, 480.f);
            self.tempScreen.frame = newRect;
        }

        completion:^{
            [self presentEditor];
        }
    ];
    
    [self.navBar.openCloseButton removeAction:nil forControlEvents:VELControlAllEvents];

    __weak id weakSelf = self;
    [self.navBar.openCloseButton addActionForControlEvents:VELControlEventClicked usingBlock:^{
        [weakSelf closeEditor];
    }];
}

- (void)closeEditor {
    NSRect rect = self.treeView.frame;
    rect.origin.y = 0;
    self.treeView.frame = rect;
    
    [self.editorView removeFromSuperview];
    self.editorView = nil;
    [self.tempScreen removeFromSuperview];
    self.tempScreen = nil;

    [self.treeView.selectedScreen setHidden:NO];
    
    [self.navBar.openCloseButton setUpward:NO animated:YES];
    [self.navBar.openCloseButton removeAction:nil forControlEvents:VELControlAllEvents];

    __weak id weakSelf = self;
    [self.navBar.openCloseButton addActionForControlEvents:VELControlEventClicked usingBlock:^{
        [weakSelf openSelectedScreen];
    }];
}

- (void)presentEditor {
    if (!self.editorView) {
        NSRect rect = self.treeView.frame;
        rect.origin.y -= rect.size.height;

        self.editorView = [[EditorView alloc] init];
        self.editorView.frame = rect;
        self.editorView.autoresizingMask = VELViewAutoresizingFlexibleWidth | VELViewAutoresizingFlexibleHeight; 

        VELWindow *window = (id)[[self.windowControllers objectAtIndex:0] window];

        NSMutableArray *subviews = [[window.rootView subviews] mutableCopy];
        NSUInteger index = [subviews indexOfObjectIdenticalTo:self.treeView];
        [subviews insertObject:self.editorView atIndex:index];
        window.rootView.subviews = subviews;
    }

    [VELView
        animateWithDuration:0.45f
        animations:^{
            NSRect editorRect = self.editorView.frame;
            editorRect.origin.y = 0;
            self.editorView.frame = editorRect;
            
            NSRect treeRect = self.treeView.frame;
            treeRect.origin.y += treeRect.size.height;
            self.treeView.frame = treeRect;
        }

        completion:^{
            [self.tempScreen removeFromSuperview];
            [self.editorView editScreen:self.treeView.selectedScreen];
        }
    ];
    
    [self.navBar.openCloseButton setUpward:YES animated:YES];
}

@end
