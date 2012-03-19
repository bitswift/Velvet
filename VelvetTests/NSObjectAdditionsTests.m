//
//  NSObjectAdditionsTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 18.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSObject+BindingsAdditions.h"

@interface TestEditorController : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign, getter = isEditing) BOOL editing;
@end

SpecBegin(NSObjectAdditions)

    __block NSTextField *textField;

    before(^{
        textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        expect(textField).not.toBeNil();
    });

    it(@"should do nothing when attempting to notify without any bindings", ^{
        [textField notifyBoundObjectsOfDidBeginEditing];
        [textField notifyBoundObjectsOfDidEndEditing];
    });

    after(^{
        [textField unbind:nil];
    });

    describe(@"with a controller", ^{
        __block TestEditorController *controller;

        before(^{
            controller = [[TestEditorController alloc] init];
            expect(controller).not.toBeNil();
        });

        after(^{
            expect(controller.editing).toBeFalsy();

            expect([^{
                [textField notifyBoundObjectsOfDidBeginEditing];
            } copy]).toInvoke(controller, @selector(objectDidBeginEditing:));

            expect(controller.editing).toBeTruthy();

            expect([^{
                [textField notifyBoundObjectsOfDidEndEditing];
            } copy]).toInvoke(controller, @selector(objectDidEndEditing:));

            expect(controller.editing).toBeFalsy();
        });

        it(@"should notify a controller bound to the text field value", ^{
            [textField bind:NSValueBinding toObject:controller withKeyPath:@"name" options:nil];
        });

        it(@"should notify a controller bound to the text field font", ^{
            [textField bind:NSFontBinding toObject:controller withKeyPath:@"name" options:nil];
        });
    });

    it(@"should notify multiple controllers of editing", ^{
        TestEditorController *firstController = [[TestEditorController alloc] init];
        TestEditorController *secondController = [[TestEditorController alloc] init];

        [textField bind:NSValueBinding toObject:firstController withKeyPath:@"name" options:nil];
        [textField bind:NSFontBinding toObject:secondController withKeyPath:@"name" options:nil];

        expect(firstController.editing).toBeFalsy();
        expect(secondController.editing).toBeFalsy();

        expect([^{
            [textField notifyBoundObjectsOfDidBeginEditing];
        } copy]).toInvoke(firstController, @selector(objectDidBeginEditing:));

        expect(firstController.editing).toBeTruthy();
        expect(secondController.editing).toBeTruthy();

        expect([^{
            [textField notifyBoundObjectsOfDidEndEditing];
        } copy]).toInvoke(secondController, @selector(objectDidEndEditing:));

        expect(firstController.editing).toBeFalsy();
        expect(secondController.editing).toBeFalsy();
    });

SpecEnd

@implementation TestEditorController
@synthesize editing = m_editing;
@synthesize name = m_name;

- (void)objectDidBeginEditing:(id)editor {
    self.editing = YES;
}

- (void)objectDidEndEditing:(id)editor {
    self.editing = NO;
}

@end
