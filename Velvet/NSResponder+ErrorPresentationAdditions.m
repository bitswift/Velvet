//
//  NSResponder+ErrorPresentationAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 15.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSResponder+ErrorPresentationAdditions.h"
#import "EXTSafeCategory.h"

@safecategory (NSResponder, ErrorPresentationAdditions)

- (void)presentError:(NSError *)error modalForWindow:(NSWindow *)window; {
    if (window) {
        [self presentError:error modalForWindow:window delegate:nil didPresentSelector:NULL contextInfo:NULL];
    } else {
        [self presentError:error];
    }
}

@end
