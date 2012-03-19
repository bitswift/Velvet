//
//  NSCell+EditorAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSCell+EditorAdditions.h"
#import "EXTSafeCategory.h"
#import "NSObject+BindingsAdditions.h"
#import <objc/runtime.h>

static BOOL (*originalTrackMouseIMP)(id, SEL, NSEvent *, NSRect, NSView *, BOOL);

static BOOL trackMouseRegisteringAsEditor (NSCell *self, SEL _cmd, NSEvent *event, NSRect cellFrame, NSView *controlView, BOOL untilMouseUp) {
    // save this into a variable, since we want to balance out the editing calls
    // even if the value changes from callbacks that occur while executing this
    // method
    BOOL registerAsEditor = self.registersAsEditorWhileTracking;

    // begin editing on all bindings
    if (registerAsEditor) {
        [controlView notifyBoundObjectsOfDidBeginEditing];
        [self notifyBoundObjectsOfDidBeginEditing];
    }

    BOOL result = originalTrackMouseIMP(self, _cmd, event, cellFrame, controlView, untilMouseUp);

    // end editing on all bindings
    if (registerAsEditor) {
        [self notifyBoundObjectsOfDidEndEditing];
        [controlView notifyBoundObjectsOfDidEndEditing];
    }

    return result;
}

@safecategory (NSCell, EditorAdditions)

- (BOOL)registersAsEditorWhileTracking {
    NSNumber *obj = objc_getAssociatedObject(self, @selector(registersAsEditorWhileTracking));
    return obj.boolValue;
}

- (void)setRegistersAsEditorWhileTracking:(BOOL)value {
    NSNumber *obj = [NSNumber numberWithBool:value];
    objc_setAssociatedObject(self, @selector(registersAsEditorWhileTracking), obj, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation NSCell (UnsafeEditorAdditions)

+ (void)load {
    Method trackMouse = class_getInstanceMethod(self, @selector(trackMouse:inRect:ofView:untilMouseUp:));
    originalTrackMouseIMP = (BOOL (*)(id, SEL, NSEvent *, NSRect, NSView *, BOOL))method_getImplementation(trackMouse);

    class_replaceMethod(self, method_getName(trackMouse), (IMP)&trackMouseRegisteringAsEditor, method_getTypeEncoding(trackMouse));
}

@end
