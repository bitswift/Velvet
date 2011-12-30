//
//  VELLabel.h
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>
#import <ApplicationServices/ApplicationServices.h>

/**
 * Describes how text should wrap or truncate.
 */
typedef enum {
    /**
     * Wrap text only at word boundaries.
     */
    VELLineBreakModeWordWrap = kCTLineBreakByWordWrapping,

    /**
     * Wrap text at the closest character boundary.
     */
    VELLineBreakModeCharacterWrap = kCTLineBreakByCharWrapping,

    /**
     * Clip rendered text when the end of the drawing rectangle is reached.
     * 
     * @warning `VELLineBreakModeClip` ignores <[VELLabel numberOfLines]>.
     */
    VELLineBreakModeClip = kCTLineBreakByClipping,

    /**
     * Truncate text as needed from the beginning of the line.
     *
     * For multiple lines of text, only text on the first line is truncated.
     */
    VELLineBreakModeHeadTruncation = kCTLineBreakByTruncatingHead,

    /**
     * Truncate text as needed from the end of the line.
     *
     * For multiple lines of text, only text on the last line is truncated.
     */
    VELLineBreakModeTailTruncation = kCTLineBreakByTruncatingTail,

    /**
     * Truncate text as needed from the middle of the line.
     *
     * For multiple lines of text, only the text in the middle of the last
     * line is truncated.
     */
    VELLineBreakModeLastLineMiddleTruncation = kCTLineBreakByTruncatingMiddle
} VELLineBreakMode;

/**
 * Describes the alignment of a line or block of text.
 */
typedef enum {
    /**
     * Text is visually left-aligned.
     */
    VELTextAlignmentLeft = kCTLeftTextAlignment,

    /**
     * Text is visually center-aligned.
     */
    VELTextAlignmentCenter = kCTCenterTextAlignment,

    /**
     * Text is visually right-aligned.
     */
    VELTextAlignmentRight = kCTRightTextAlignment,

    /**
     * Everything but the last line of text is fully justified. The last line of
     * text is naturally aligned.
     */
    VELTextAlignmentJustified = kCTJustifiedTextAlignment,

    /**
     * Text uses its script's natural alignment.
     */
    VELTextAlignmentNatural = kCTNaturalTextAlignment
} VELTextAlignment;

/**
 * A simple text label.
 */
@interface VELLabel : VELView

/**
 * @name Displaying Text
 */

/**
 * The text displayed in the receiver, formatted with any desired Core Text
 * attributes.
 *
 * This attributed string is the combination of all other formatting and text
 * properties on the receiver, and determines their values.
 */
@property (nonatomic, copy) NSAttributedString *formattedText;

/**
 * The unformatted text displayed in the receiver.
 *
 * Setting this property will replace all the characters of <formattedText>,
 * according to the semantics of `-[NSMutableAttributedString
 * replaceCharactersInRange:withString:]`.
 */
@property (nonatomic, copy) NSString *text;

/**
 * The font for the text of the receiver.
 *
 * Setting this property will apply a font attribute to the whole
 * <formattedText> string, replacing any existing font attribute(s).
 *
 * When reading this property, if <formattedText> contains multiple font
 * attributes, this will return the first one.
 */
@property (nonatomic, copy) NSFont *font;

/**
 * The color of the text in the receiver.
 *
 * Setting this property will apply a color attribute to the whole
 * <formattedText> string, replacing any existing color attribute(s).
 *
 * When reading this property, if <formattedText> contains multiple color
 * attributes, this will return the first one.
 */
@property (nonatomic, copy) NSColor *textColor;

/**
 * The maximum number of lines to draw the formatted text into.
 * 
 * If `numberOfLines` is 0, text will be drawn using as many lines
 * as required.
 * 
 * If the text doesn't fit in the number of lines specified, within the
 * bounds of the control, it will be truncated.
 * 
 * Defaults to 1.
 */
@property (nonatomic, assign) NSUInteger numberOfLines;

/**
 * How the the text of the label should wrap or truncate, if it is too large for
 * the label's bounds.
 *
 * Setting this property will apply a paragraph style to the whole
 * <formattedText> string. Any existing paragraph style(s) will be replaced with
 * one constructed from the values of this property and <textAlignment>.
 *
 * When reading this property, if <formattedText> contains multiple paragraph
 * styles, this will return the line break mode of the first one.
 */
@property (nonatomic, assign) VELLineBreakMode lineBreakMode;

/**
 * How the text of the label should be aligned.
 *
 * Setting this property will apply a paragraph style to the whole
 * <formattedText> string. Any existing paragraph style(s) will be replaced with
 * one constructed from the values of this property and <lineBreakMode>.
 *
 * When reading this property, if <formattedText> contains multiple paragraph
 * styles, this will return the text alignment of the first one.
 */
@property (nonatomic, assign) VELTextAlignment textAlignment;

@end
