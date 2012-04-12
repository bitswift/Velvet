//
//  NSPopUpButtonCell+EditorAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSPopUpButtonCell+EditorAdditions.h"
#import "NSCell+EditorAdditions.h"
#import "NSObject+BindingsAdditions.h"
#import "EXTSafeCategory.h"
#import <objc/runtime.h>

static void (*originalAttachPopUpIMP)(id, SEL, NSRect, NSView *);
static void (*originalDismissPopUpIMP)(id, SEL);

static void attachPopUpRegisteringAsEditor (NSPopUpButtonCell *self, SEL _cmd, NSRect frame, NSView *controlView) {
    if (self.registersAsEditorWhileTracking && !self.editing) {
        self.editing = YES;

        [controlView notifyBoundObjectsOfDidBeginEditing];
        [self notifyBoundObjectsOfDidBeginEditing];
    }

    originalAttachPopUpIMP(self, _cmd, frame, controlView);
}

static void dismissPopUpUnregisteringAsEditor (NSPopUpButtonCell *self, SEL _cmd) {
    NSView *controlView = self.controlView;

    originalDismissPopUpIMP(self, _cmd);

    if (self.registersAsEditorWhileTracking && self.editing) {
        self.editing = NO;

        // end editing after one run loop iteration, so the message is only sent
        // after any model change has occurred
        [self performSelector:@selector(notifyBoundObjectsOfDidEndEditing) withObject:nil afterDelay:0];
        [controlView performSelector:@selector(notifyBoundObjectsOfDidEndEditing) withObject:nil afterDelay:0];
    }
}

@safecategory(NSPopUpButtonCell, EditorAdditions)
- (BOOL)isEditing {
    NSNumber *num = objc_getAssociatedObject(self, @selector(isEditing));
    return [num boolValue];
}

- (void)setEditing:(BOOL)editing {
    NSNumber *num = [NSNumber numberWithBool:editing];
    objc_setAssociatedObject(self, @selector(isEditing), num, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end

@implementation NSPopUpButtonCell (UnsafeEditorAdditions)

+ (void)load {
    Method attachPopUp = class_getInstanceMethod(self, @selector(attachPopUpWithFrame:inView:));
    Method dismissPopUp = class_getInstanceMethod(self, @selector(dismissPopUp));

    originalAttachPopUpIMP = (void (*)(id, SEL, NSRect, NSView *))method_getImplementation(attachPopUp);
    originalDismissPopUpIMP = (void (*)(id, SEL))method_getImplementation(dismissPopUp);

    class_replaceMethod(self, method_getName(attachPopUp), (IMP)&attachPopUpRegisteringAsEditor, method_getTypeEncoding(attachPopUp));
    class_replaceMethod(self, method_getName(dismissPopUp), (IMP)&dismissPopUpUnregisteringAsEditor, method_getTypeEncoding(dismissPopUp));
}

@end
