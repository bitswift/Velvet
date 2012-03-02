//
//  NSWindow+ResponderChainAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSWindow+ResponderChainAdditions.h"
#import "NSResponder+ResponderChainAdditions.h"
#import "EXTSafeCategory.h"

@safecategory (NSWindow, ResponderChainAdditions)

- (BOOL)makeFirstResponderIfNotInResponderChain:(NSResponder *)responder; {
    NSResponder *existingResponder = self.firstResponder;

    if ([responder isNextResponderOf:existingResponder])
        return YES;
    else
        return [self makeFirstResponder:responder];
}

@end
