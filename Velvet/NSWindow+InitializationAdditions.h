//
//  NSWindow+InitializationAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 15.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

/**
 * Extensions to `NSWindow` that make it easier to instantiate.
 */
@interface NSWindow (InitializationAdditions)

/**
 * Initializes the receiver as a titled, closable, miniaturizable, and resizable
 * window.
 *
 * @param rect The window's content area on screen.
 */
- (id)initWithContentRect:(NSRect)rect;

/**
 * Initializes the receiver with the given style.
 *
 * @param rect The window's content area on screen.
 * @param style A bitmask of window style flags that describe the style of the
 * window.
 */
- (id)initWithContentRect:(NSRect)rect styleMask:(NSUInteger)style;

@end
