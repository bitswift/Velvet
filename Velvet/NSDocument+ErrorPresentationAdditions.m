//
//  NSDocument+ErrorPresentationAdditions.m
//  Velvet
//
//  Created by Josh Vera on 3/26/12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSDocument+ErrorPresentationAdditions.h"
#import "EXTSafeCategory.h"

@safecategory (NSDocument, ErrorPresentationAdditions)

- (void)presentError:(NSError *)error modalForWindow:(NSWindow *)window; {
    if (window) {
        [self presentError:error modalForWindow:window delegate:nil didPresentSelector:NULL contextInfo:NULL];
    } else {
        [self presentError:error];
    }
}
@end
