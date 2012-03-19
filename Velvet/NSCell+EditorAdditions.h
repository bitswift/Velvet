//
//  NSCell+EditorAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Extensions to `NSCell` that support the behaviors of the `<NSEditor>`
 * informal protocol.
 */
@interface NSCell (EditorAdditions)

/**
 * @name Editor Registration
 */

/**
 * Whether the receiver should register itself as an editor with all of its
 * bindings and its control's bindings while tracking the mouse.
 *
 * In other words, if this is `YES`, the receiver will send an
 * `objectDidBeginEditing:` message to each object bound (with it or its
 * control) when mouse tracking begins, and an `objectDidEndEditing:` message to
 * each object bound (with it or its control) when mouse tracking ends.
 *
 * The default value for this property is `NO`.
 */
@property (nonatomic, assign) BOOL registersAsEditorWhileTracking;
@end
