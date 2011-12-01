//
//  Document.h
//  TransitionTest
//
//  Created by Justin Spahr-Summers on 30.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>
#import "NavigationBar.h"
#import "TreeView.h"
#import "EditorView.h"

@interface Document : NSDocument

- (void)openSelectedScreen;
- (void)closeEditor;
- (void)presentEditor;

@property (nonatomic, strong) NavigationBar *navBar;
@property (nonatomic, strong) TreeView *treeView;
@property (nonatomic, strong) EditorView *editorView;
@property (nonatomic, strong) Screen *tempScreen;

@end
