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

@interface VELLabelTests ()
- (void)verifyLabelSize:(VELLabel *)label;
@end

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

- (void)testLineBreakMode {
    VELLineBreakMode lineBreakMode = VELLineBreakModeClip;

    VELLabel *label = [[VELLabel alloc] init];
    label.lineBreakMode = lineBreakMode;

    STAssertEquals(label.lineBreakMode, lineBreakMode, @"");
}

- (void)testTextAlignment {
    VELTextAlignment textAlignment = VELTextAlignmentJustified;

    VELLabel *label = [[VELLabel alloc] init];
    label.textAlignment = textAlignment;

    STAssertEquals(label.textAlignment, textAlignment, @"");

    NSDictionary *attributes = [label.formattedText attributesAtIndex:0 effectiveRange:NULL];
    STAssertNotNil(attributes, @"");

    CTParagraphStyleRef style = (__bridge CTParagraphStyleRef)[attributes objectForKey:NSParagraphStyleAttributeName];

    CTTextAlignment styleAlignment;
    STAssertTrue(CTParagraphStyleGetValueForSpecifier(style, kCTParagraphStyleSpecifierAlignment, sizeof(styleAlignment), &styleAlignment), @"");

    STAssertTrue(styleAlignment = kCTJustifiedTextAlignment, @"");
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

- (void)testNumberOfLines {
    VELLabel *label = [[VELLabel alloc] init];
    label.text = @"This is a really long string. This is a really long string. This is a really long string. This is a really long string.";

    STAssertEquals(label.numberOfLines, (NSUInteger)1, @"");
    [self verifyLabelSize:label];
}

- (void)testSizingWithLineBreakMode {
    VELLabel *label = [[VELLabel alloc] init];
    label.text = @"This is a really long string. This is a really long string. This is a really long string. This is a really long string.";

    // make sure that the label still sizes to multiple lines with a different
    // line break mode
    label.lineBreakMode = VELLineBreakModeLastLineMiddleTruncation;
    [self verifyLabelSize:label];
}

- (void)verifyLabelSize:(VELLabel *)label; {
    label.numberOfLines = 1;

    CGFloat width = 80;
    CGSize singleLineSize = [label sizeThatFits:CGSizeMake(width, 0)];
    NSLog(@"singleLineSize: %@", NSStringFromSize(singleLineSize));
    
    STAssertTrue(singleLineSize.width > width, @"");
    STAssertTrue(singleLineSize.height > 0.0f, @"");
    
    label.numberOfLines = 3;
    CGSize multiLineSize = [label sizeThatFits:CGSizeMake(width, 0)];
    NSLog(@"multiLineSize: %@", NSStringFromSize(multiLineSize));
    
    STAssertTrue(multiLineSize.width <= singleLineSize.width, @"");
    STAssertTrue(multiLineSize.height > singleLineSize.height, @"");
}

- (void)testSetTextEmptyString {
    VELLabel *label = [[VELLabel alloc] init];
    NSFont *font = [NSFont systemFontOfSize:24];

    label.text = @"Some text.";
    label.textAlignment = VELTextAlignmentCenter;
    label.font = font;

    label.text = @"";
    // Test that setting the text to an empty string keeps the formatting
    STAssertEqualObjects(label.font, font, @"");
    STAssertEquals(label.textAlignment, VELTextAlignmentCenter, @"");
    STAssertEquals([label.text length], (NSUInteger)0, @"");
}

- (void)testSetTextNil {
    VELLabel *label = [[VELLabel alloc] init];
    NSFont *font = [NSFont systemFontOfSize:24];

    label.text = @"Some text.";
    label.textAlignment = VELTextAlignmentCenter;
    label.font = font;

    label.text = nil;
    // Test that setting the text to nil keeps the formatting
    STAssertEqualObjects(label.font, font, @"");
    STAssertEquals(label.textAlignment, VELTextAlignmentCenter, @"");
    STAssertEquals([label.text length], (NSUInteger)0, @"");
}

@end
