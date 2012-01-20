//
//  NSWindow+InitializationAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 15.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSWindow+InitializationAdditions.h"
#import "EXTSafeCategory.h"

@safecategory (NSWindow, InitializationAdditions)

- (id)initWithContentRect:(NSRect)rect; {
    return [self initWithContentRect:rect styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask];
}

- (id)initWithContentRect:(NSRect)rect styleMask:(NSUInteger)style; {
    return [self initWithContentRect:rect styleMask:style backing:NSBackingStoreBuffered defer:YES];
}

@end
