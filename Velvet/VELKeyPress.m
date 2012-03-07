//
//  VELKeyPress.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 06.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "VELKeyPress.h"

@implementation VELKeyPress

#pragma mark Properties

@synthesize charactersIgnoringModifiers = m_charactersIgnoringModifiers;
@synthesize modifierFlags = m_modifierFlags;
@synthesize event = m_event;

#pragma mark Lifecycle

- (id)init {
    return [self initWithCharactersIgnoringModifiers:nil modifierFlags:0];
}

- (id)initWithEvent:(NSEvent *)event; {
    NSParameterAssert(event != nil);

    self = [self initWithCharactersIgnoringModifiers:event.charactersIgnoringModifiers modifierFlags:event.modifierFlags];
    if (!self)
        return nil;

    m_event = [event copy];
    return self;
}

- (id)initWithCharactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers modifierFlags:(NSUInteger)modifierFlags; {
    self = [super init];
    if (!self)
        return nil;

    m_charactersIgnoringModifiers = [charactersIgnoringModifiers copy];
    m_modifierFlags = modifierFlags;
    return self;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
    NSString *characters = [coder decodeObjectForKey:@"charactersIgnoringModifiers"];
    NSUInteger modifierFlags = [[coder decodeObjectForKey:@"modifierFlags"] unsignedIntegerValue];

    self = [self initWithCharactersIgnoringModifiers:characters modifierFlags:modifierFlags];
    if (!self)
        return nil;

    m_event = [coder decodeObjectForKey:@"event"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.charactersIgnoringModifiers)
        [coder encodeObject:self.charactersIgnoringModifiers forKey:@"charactersIgnoringModifiers"];

    if (self.event)
        [coder encodeObject:self.event forKey:@"event"];

    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.modifierFlags] forKey:@"modifierFlags"];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark NSObject overrides

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>( characters = \"%@\", modifiers = %lu )", [self class], self, self.charactersIgnoringModifiers, (unsigned long)self.modifierFlags];
}

- (NSUInteger)hash {
    return [self.charactersIgnoringModifiers hash] ^ self.modifierFlags;
}

- (BOOL)isEqual:(VELKeyPress *)obj {
    if (![obj isKindOfClass:[VELKeyPress class]])
        return NO;

    if ((self.charactersIgnoringModifiers.length == 0) != (obj.charactersIgnoringModifiers.length == 0))
        return NO;

    if (self.charactersIgnoringModifiers && ![self.charactersIgnoringModifiers isEqual:obj.charactersIgnoringModifiers])
        return NO;

    if (self.modifierFlags != obj.modifierFlags)
        return NO;

    return YES;
}

@end
