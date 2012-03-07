//
//  VELKeyPressTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 06.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELKeyPress.h>

SpecBegin(VELKeyPress)

    NSString *characters = @"S";
    NSUInteger modifiers = NSAlternateKeyMask;

    __block VELKeyPress *keyPress;

    before(^{
        keyPress = [[VELKeyPress alloc] initWithCharactersIgnoringModifiers:characters modifierFlags:modifiers];
        expect(keyPress).not.toBeNil();

        expect(keyPress.event).toBeNil();
        expect(keyPress.charactersIgnoringModifiers).toEqual(characters);
        expect(keyPress.modifierFlags).toEqual(modifiers);
    });

    it(@"should be equal to key press initialized with the same information", ^{
        VELKeyPress *equalKeyPress = [[VELKeyPress alloc] initWithCharactersIgnoringModifiers:characters modifierFlags:modifiers];
        expect(equalKeyPress).toEqual(keyPress);
    });

    it(@"should not be equal to key press initialized with different characters", ^{
        VELKeyPress *inequalKeyPress = [[VELKeyPress alloc] initWithCharactersIgnoringModifiers:@"s" modifierFlags:modifiers];
        expect(inequalKeyPress).not.toEqual(keyPress);
    });

    it(@"should not be equal to key press initialized with different modifiers", ^{
        VELKeyPress *inequalKeyPress = [[VELKeyPress alloc] initWithCharactersIgnoringModifiers:characters modifierFlags:0];
        expect(inequalKeyPress).not.toEqual(keyPress);
    });

    it(@"should implement <NSCoding>", ^{
        expect(keyPress).toSupportArchiving();
    });

    it(@"should implement <NSCopying>", ^{
        expect(keyPress).toSupportCopying();
    });

SpecEnd
