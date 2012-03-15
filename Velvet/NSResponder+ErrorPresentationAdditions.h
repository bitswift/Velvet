//
//  NSResponder+ErrorPresentationAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 15.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Extensions to `NSResponder` to make presenting errors easier.
 */
@interface NSResponder (ErrorPresentationAdditions)

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
