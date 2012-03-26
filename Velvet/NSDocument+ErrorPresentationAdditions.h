//
//  NSDocument+ErrorPresentationAdditions.h
//  Velvet
//
//  Created by Josh Vera on 3/26/12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Extensions to `NSDocument` to make presenting errors easier.
 */
@interface NSDocument (ErrorPresentationAdditions)

/**
 * @name Presenting Error Sheets
 */

/**
 * Presents the given error in a sheet attached to the given window.
 *
 * If `window` is `nil`, this will present an application-modal alert instead.
 *
 * @param error An error to present.
 * @param window A window to attach the sheet to.
 */
- (void)presentError:(NSError *)error modalForWindow:(NSWindow *)window;

@end