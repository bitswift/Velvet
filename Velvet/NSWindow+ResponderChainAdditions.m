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
#import <objc/runtime.h>

NSString * const VELNSWindowFirstResponderDidChangeNotification = @"VELNSWindowFirstResponderDidChangeNotification";
NSString * const VELNSWindowOldFirstResponderKey = @"VELNSWindowOldFirstResponderKey";
NSString * const VELNSWindowNewFirstResponderKey = @"VELNSWindowNewFirstResponderKey";

static BOOL (*originalMakeFirstResponderIMP)(id, SEL, NSResponder *);

static BOOL makeFirstResponderAndPostNotification (NSWindow *self, SEL _cmd, NSResponder *responder) {
    id previousResponder = self.firstResponder ?: [NSNull null];
    
    BOOL success = originalMakeFirstResponderIMP(self, _cmd, responder);
    if (!success)
        return NO;
    
    id newResponder = self.firstResponder ?: [NSNull null];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        previousResponder, VELNSWindowOldFirstResponderKey,
        newResponder, VELNSWindowNewFirstResponderKey,
        nil
    ];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:VELNSWindowFirstResponderDidChangeNotification
        object:self
        userInfo:userInfo
     ];
    
    return success;
    
}

@safecategory (NSWindow, ResponderChainAdditions)

- (BOOL)makeFirstResponderIfNotInResponderChain:(NSResponder *)responder; {
    NSResponder *existingResponder = self.firstResponder;

    if ([responder isNextResponderOf:existingResponder])
        return YES;
    else
        return [self makeFirstResponder:responder];
}

@end

@implementation NSWindow (FirstResponderAdditions)

+ (void)load {
    Method makeFirstResponder = class_getInstanceMethod(self, @selector(makeFirstResponder:));
    originalMakeFirstResponderIMP = (BOOL (*)(id, SEL, NSResponder *))method_getImplementation(makeFirstResponder);
    
    class_replaceMethod(self, method_getName(makeFirstResponder), (IMP)&makeFirstResponderAndPostNotification, method_getTypeEncoding(makeFirstResponder));
}

@end
