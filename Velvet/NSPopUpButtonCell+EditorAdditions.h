//
//  NSPopUpButtonCell+EditorAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Implements <[NSCell registersAsEditorWhileTracking]> for `NSPopUpButtonCell`.
 */
@interface NSPopUpButtonCell (EditorAdditions)

/**
 * @name Editing Status
 */

/**
 * Whether the receiver is currently registered as editing.
 */
@property (nonatomic, getter = isEditing, assign) BOOL editing;
@end
