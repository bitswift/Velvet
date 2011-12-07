//
//  VELLabelTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 07.12.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import "VELLabelTests.h"
#import <Cocoa/Cocoa.h>
#import <Velvet/Velvet.h>

@implementation VELLabelTests

- (void)testInitialization {
    VELLabel *label = [[VELLabel alloc] init];
    STAssertNotNil(label, @"");
}

- (void)testText {
    NSString *text = @"foobar";
    
    VELLabel *label = [[VELLabel alloc] init];
    label.text = text;

    STAssertEqualObjects(label.text, text, @"");
    STAssertEqualObjects(label.formattedText.string, text, @"");
}

- (void)testFont {
    NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSize]];

    VELLabel *label = [[VELLabel alloc] init];
    label.font = font;

    STAssertEqualObjects(label.font, font, @"");

    NSDictionary *attributes = [label.formattedText attributesAtIndex:0 effectiveRange:NULL];
    STAssertNotNil(attributes, @"");

    STAssertEqualObjects([attributes objectForKey:NSFontAttributeName], font, @"");
}

- (void)testColor {
    NSColor *color = [NSColor greenColor];

    VELLabel *label = [[VELLabel alloc] init];
    label.textColor = color;

    STAssertEqualObjects(label.textColor, color, @"");

    NSDictionary *attributes = [label.formattedText attributesAtIndex:0 effectiveRange:NULL];
    STAssertNotNil(attributes, @"");

    STAssertEqualObjects([attributes objectForKey:NSForegroundColorAttributeName], color, @"");
}

- (void)testFormattedText {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"The quick brown fox jumped over the lazy dog."];

    NSFont *firstFont = [NSFont systemFontOfSize:[NSFont labelFontSize]];
    [string addAttribute:NSFontAttributeName value:firstFont range:NSMakeRange(0, 1)];

    NSFont *secondFont = [NSFont boldSystemFontOfSize:[NSFont systemFontSize]];
    [string addAttribute:NSFontAttributeName value:secondFont range:NSMakeRange(3, 6)];

    NSColor *firstColor = [NSColor blueColor];
    [string addAttribute:NSForegroundColorAttributeName value:firstColor range:NSMakeRange(0, 4)];

    NSColor *secondColor = [NSColor blackColor];
    [string addAttribute:NSForegroundColorAttributeName value:secondColor range:NSMakeRange(2, 5)];

    VELLabel *label = [[VELLabel alloc] init];
    label.formattedText = string;

    STAssertEqualObjects(label.formattedText, string, @"");

    STAssertEqualObjects(label.text, string.string, @"");
    STAssertEqualObjects(label.font, firstFont, @"");
    STAssertEqualObjects(label.textColor, firstColor, @"");
}

@end
