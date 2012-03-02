//
//  NSResponder+ResponderChainAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 01.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSResponder+ResponderChainAdditions.h"
#import "EXTSafeCategory.h"

@safecategory (NSResponder, ResponderChainAdditions)

- (BOOL)isNextResponderOf:(NSResponder *)responder; {
    while (responder) {
        if (self == responder)
            return YES;

        responder = responder.nextResponder;
    }

    return NO;
}

@end
