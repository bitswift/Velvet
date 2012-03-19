//
//  NSObject+BindingsAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSObject+BindingsAdditions.h"
#import "EXTSafeCategory.h"

/**
 * For every binding on `object`, registers or unregisters from editing.
 *
 * @param object The object whose bindings should be sent the
 * `<NSEditorRegistration>` message.
 * @param editing Whether the object has begun editing. If this is `NO`, the
 * object is assumed to have ended editing.
 */
static void updateEditingStatusWithBindings (id object, BOOL editing) {
    NSArray *bindings = [object exposedBindings];
    for (NSString *key in bindings) {
        NSDictionary *info = [object infoForBinding:key];
        id observedObject = [info objectForKey:NSObservedObjectKey];

        if (editing)
            [observedObject objectDidBeginEditing:object];
        else
            [observedObject objectDidEndEditing:object];
    }
}


@safecategory (NSObject, BindingsAdditions)

- (void)notifyBoundObjectsOfDidBeginEditing; {
    updateEditingStatusWithBindings(self, YES);
}

- (void)notifyBoundObjectsOfDidEndEditing; {
    updateEditingStatusWithBindings(self, NO);
}

@end
