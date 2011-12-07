//
//  VELLabel.h
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>

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

@end
