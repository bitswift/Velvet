//
//  NSResponder+ResponderChainAdditions.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Extensions to `NSResponder` for inspecting the responder chain.
 */
@interface NSResponder (ResponderChainAdditions)

/**
 * Returns whether the receiver is the given object, or one of its next
 * responders.
 *
 * This will walk up the responder chain starting from `responder`, and return
 * `YES` if the receiver exists anywhere in the chain.
 *
 * @param responder A responder which the receiver may be the next responder of.
 */
- (BOOL)isNextResponderOf:(NSResponder *)responder;

@end
