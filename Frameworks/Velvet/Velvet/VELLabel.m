//
//  VELLabel.m
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELLabel.h>
#import <Proton/EXTScope.h>

#define VELLabelPadding 2.0f

static NSString * const VELLabelEmptyAttributedString = @"\0";

static NSRange NSRangeFromCFRange(CFRange range) {
    NSUInteger loc = range.location == kCFNotFound ? NSNotFound : (NSUInteger)range.location;
    return NSMakeRange(loc, (NSUInteger)range.length);
}

@interface VELLabel ()
/*
 * Sets an attribute over the full length of the <formattedText>.
 *
 * This will replace any existing attributes with the given name.
 *
 * @param attributeName The name of the attribute to set.
 * @param value The value of the attribute. If this argument is `nil`, any
 * existing attributes are removed instead of being replaced.
 */
- (void)setAttribute:(NSString *)attributeName value:(id)value;

/*
 * Replaces the paragraph style of the <formattedText> with one created from the
 * receiver's style properties.
 */
- (void)setParagraphStyle;

/*
 * Returns an array of all lines necessary to draw the full <formattedText>
 * within the width of the label's bounds.
 */
- (NSArray *)linesToDraw;

@end

@implementation VELLabel

#pragma mark Properties

@synthesize formattedText = m_formattedText;
@synthesize numberOfLines = m_numberOfLines;
@synthesize lineBreakMode = m_lineBreakMode;
@synthesize textAlignment = m_textAlignment;

- (void)setFormattedText:(NSAttributedString *)str {
    m_formattedText = [str copy];
    [self.layer setNeedsDisplay];
}

- (NSString *)text {
    NSString *str = self.formattedText.string;

    if ([str isEqualToString:VELLabelEmptyAttributedString])
        return nil;
    else
        return str;
}

- (void)setText:(NSString *)text {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:VELLabelEmptyAttributedString];

    if (self.formattedText)
        [attributedString setAttributedString:self.formattedText];

    if (![text length])
        text = VELLabelEmptyAttributedString;

    [attributedString replaceCharactersInRange:NSMakeRange(0, attributedString.length) withString:text];

    self.formattedText = attributedString;
}

- (NSFont *)font {
    return [self.formattedText attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
}

- (void)setFont:(NSFont *)font {
    [self setAttribute:NSFontAttributeName value:font];
}

- (NSColor *)textColor {
    return [self.formattedText attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL];
}

- (void)setTextColor:(NSColor *)color {
    [self setAttribute:NSForegroundColorAttributeName value:color];
}

- (VELLineBreakMode)lineBreakMode {
    CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[self.formattedText attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];

    CTLineBreakMode lineBreakMode = 0;

    if (paragraphStyle) {
        CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierLineBreakMode, sizeof(lineBreakMode), &lineBreakMode);
    }

    return lineBreakMode;
}

- (void)setLineBreakMode:(VELLineBreakMode)mode {
    m_lineBreakMode = mode;
    [self setParagraphStyle];
}

- (void)setNumberOfLines:(NSUInteger)numberOfLines {
    m_numberOfLines = numberOfLines;
    [self setNeedsDisplay];
}

- (VELTextAlignment)textAlignment {
    CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[self.formattedText attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];

    CTTextAlignment textAlignment = 0;

    if (paragraphStyle) {
        CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &textAlignment);
    }

    return textAlignment;
}

- (void)setTextAlignment:(VELTextAlignment)alignment {
    m_textAlignment = alignment;
    [self setParagraphStyle];
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    // don't automatically clear the context -- we'll fill it with our
    // background color in drawRect: so that we get SPAA on top
    self.clearsContextBeforeDrawing = NO;

    self.backgroundColor = [NSColor clearColor];
    self.numberOfLines = 1;
    self.userInteractionEnabled = NO;

    return self;
}


#pragma mark Line Calculations

- (NSArray *)linesToDraw {
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.formattedText);
    CFIndex strLength = (CFIndex)self.formattedText.length;
    CFIndex characterIndex = 0;
    NSMutableArray *lines = [NSMutableArray array];
    
    while (characterIndex < strLength) {
        CFIndex characterCount = 0;
        
        switch (self.lineBreakMode) {
            case VELLineBreakModeCharacterWrap:
                characterCount = CTTypesetterSuggestClusterBreak(typesetter, characterIndex, self.bounds.size.width - VELLabelPadding * 2);
                break;
            case VELLineBreakModeClip:
                characterCount = strLength;
                break;
            case VELLineBreakModeWordWrap:
            // Truncation is treated similar to word wrap before we condense it down and add an elipsis
            case VELLineBreakModeHeadTruncation:
            case VELLineBreakModeMiddleTruncation:
            case VELLineBreakModeTailTruncation:
            default:
                characterCount = CTTypesetterSuggestLineBreak(typesetter, characterIndex, self.bounds.size.width - VELLabelPadding * 2);
                break;
        }
        
        CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(characterIndex, characterCount));
        [lines addObject:(__bridge id)line];
        characterIndex += characterCount;
    }
    
    return [NSArray arrayWithArray:lines];
}

#pragma mark Drawing


- (void)drawRect:(CGRect)rect {
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;

    // clear our context to our background color
    if (self.layer.backgroundColor) {
        CGContextSetFillColorWithColor(context, self.layer.backgroundColor);
        CGContextFillRect(context, rect);
    } else {
        CGContextClearRect(context, rect);
    }

    NSAttributedString *attributedString = self.formattedText;
    if ([attributedString.string isEqualToString:VELLabelEmptyAttributedString])
        return;

    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    NSArray *lines = [self linesToDraw];
    
    // Determine if we have more lines than will fit vertically in our bounds
    CGFloat height = 0.0f;
    NSUInteger visibleLineCount = 0;
    NSUInteger i;
    for (i = 0; i < lines.count; i++) {
        CTLineRef aLine = (__bridge CTLineRef)[lines objectAtIndex:i];
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CTLineGetTypographicBounds(aLine, &ascent, &descent, &leading);
        height += ceil(ascent + descent + leading);
        
        if (height > self.bounds.size.height - VELLabelPadding * 2) {
            break;
        }
        visibleLineCount++;
    }
    
    // If we have more lines than will fit and the label uses truncation, we'll need to cull the lines
    if (visibleLineCount < lines.count) {
        CTLineRef ellipsisLine = NULL;
        CFAttributedStringRef ellipsisAttributedString = CFAttributedStringCreate(NULL, (CFStringRef) @"…", NULL);
        @onExit {
            CFRelease(ellipsisAttributedString);
        };
        ellipsisLine = CTLineCreateWithAttributedString(ellipsisAttributedString);        
        @onExit {
            CFRelease(ellipsisLine);
        };
        
        if (self.lineBreakMode == VELLineBreakModeHeadTruncation) {
            if (visibleLineCount == 0) {
                lines = [NSArray array];
            } else {
                // Calculate the truncated first line if we have more lines than will be drawn
                //   and the label uses VELLineBreakModeHeadTruncation
                CTLineRef firstVisibleLine = (__bridge CTLineRef)[lines objectAtIndex:lines.count - visibleLineCount];
                NSRange firstLineRange = NSRangeFromCFRange(CTLineGetStringRange(firstVisibleLine));
                // what we really want is a range from the beginning to the end of `firstVisibleLine`
                firstLineRange.length = firstLineRange.location + firstLineRange.length;
                firstLineRange.location = 0;
                
                NSAttributedString *firstLineAttrStr = [attributedString attributedSubstringFromRange:firstLineRange];
                CTLineRef firstLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)firstLineAttrStr);
                firstLine = CTLineCreateTruncatedLine(firstLine, self.bounds.size.width - VELLabelPadding * 2, kCTLineTruncationStart, ellipsisLine);
                
                // Replace the first line with our truncated version
                NSArray *newLines = [NSArray arrayWithObject:(__bridge id)firstLine];
                lines = [newLines arrayByAddingObjectsFromArray:[lines subarrayWithRange:NSMakeRange(lines.count - visibleLineCount + 1, visibleLineCount - 1)]];
            }
        } else if (self.lineBreakMode == VELLineBreakModeMiddleTruncation ||
                   self.lineBreakMode == VELLineBreakModeTailTruncation) {
            if (visibleLineCount == 0) {
                lines = [NSArray array];
            } else {
                // Calculate the truncated last line if we have more lines than will be drawn
                //   and the label has truncation affecting the last line
                CTLineRef lastVisibleLine = (__bridge CTLineRef)[lines objectAtIndex:visibleLineCount - 1];
                NSRange lastLineRange = NSRangeFromCFRange(CTLineGetStringRange(lastVisibleLine));
                lastLineRange.length = attributedString.length - lastLineRange.location;
                
                NSAttributedString *lastLineAttrStr = [attributedString attributedSubstringFromRange:lastLineRange];
                CTLineRef lastLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)lastLineAttrStr);
                
                switch (self.lineBreakMode) {
                    case VELLineBreakModeMiddleTruncation:
                        lastLine = CTLineCreateTruncatedLine(lastLine, self.bounds.size.width - VELLabelPadding * 2, kCTLineTruncationMiddle, ellipsisLine);
                        break;
                    case VELLineBreakModeTailTruncation:
                    default:
                        lastLine = CTLineCreateTruncatedLine(lastLine, self.bounds.size.width - VELLabelPadding * 2, kCTLineTruncationEnd, ellipsisLine);
                        break;
                }
                
                lines = [lines subarrayWithRange:NSMakeRange(0, visibleLineCount - 1)];
                lines = [lines arrayByAddingObject:(__bridge id)lastLine];
            }
        }
    }
    
    // Draw all the visible lines
    CGFloat originY = 0.0f;
    for (i = 0; i < lines.count; i++) {
        CTLineRef aLine = (__bridge CTLineRef)[lines objectAtIndex:i];
        
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CGFloat lineWidth = CTLineGetTypographicBounds(aLine, &ascent, &descent, &leading);
        
        originY += ceil(ascent + leading);
        
        CGFloat indentWidth = VELLabelPadding;
        switch (self.textAlignment) {
            case VELTextAlignmentCenter:
                indentWidth = floor(((self.bounds.size.width - VELLabelPadding * 2) - (lineWidth - CTLineGetTrailingWhitespaceWidth(aLine)))/2.0f + VELLabelPadding);
                break;
            case VELTextAlignmentRight:
                // It may not be appropriate to floor `indentWidth` when using `VELTextAlignmentRight`
                indentWidth = (self.bounds.size.width - VELLabelPadding * 2) - (lineWidth - CTLineGetTrailingWhitespaceWidth(aLine)) + VELLabelPadding;
                break;
            default:
                break;
        }
        
        CGContextSetTextPosition(context, indentWidth, (self.bounds.size.height - VELLabelPadding) - originY);
        if (i < lines.count - 1 && self.textAlignment == kCTJustifiedTextAlignment) {
            // Only create justified lines if we are NOT at the last line yet
            aLine = CTLineCreateJustifiedLine(aLine, 1.0f, self.bounds.size.width - VELLabelPadding * 2);
        }
        CTLineDraw(aLine, context);
        originY += descent;
    }
}

- (CGSize)sizeThatFits:(CGSize)constraint {
    if (!self.formattedText)
        return CGSizeZero;
    
    NSUInteger maximumLines = self.numberOfLines;

    // if one line, don't constrain the width (the text should be as wide as necessary)
    if (maximumLines == 1 || constraint.width == 0)
        constraint.width = CGFLOAT_MAX;
    
    // if not one line, don't constrain the height (the text block should be as tall as necessary)
    if (maximumLines != 1 || constraint.height == 0)
        constraint.height = CGFLOAT_MAX;
    
    // subtract our padding here, we'll add it back in at the end after we figure out the text size
    constraint.width -= VELLabelPadding * 2;
    constraint.height -= VELLabelPadding * 2;

    NSMutableAttributedString *string = [self.formattedText mutableCopy];

    // remove all paragraph styles (such as line break mode and alignment) so
    // that the size returned is as much space as the full, left-aligned text
    // would take -- and then can be reduced from there when rendered
    [string removeAttribute:NSParagraphStyleAttributeName range:NSMakeRange(0, [string length])];

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
    @onExit {
        CFRelease(framesetter);
    };
    
    CFRange entireRange = CFRangeMake(0, 0);
    
    // the range of text that we will actually display
    CFRange desiredRange;
    
    if (maximumLines == 0) {
        desiredRange = entireRange;
    } else {
        CGMutablePathRef path = CGPathCreateMutable();
        @onExit {
            CGPathRelease(path);
        };
        
        CGPathAddRect(path, NULL, CGRectMake(0, 0, constraint.width, constraint.height));
        
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, entireRange, path, NULL);
        @onExit {
            CFRelease(frame);
        };
        
        NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frame);
        NSUInteger count = [lines count];
        if (!count) {
            return CGSizeZero;
        }
        
        NSUInteger lastIndex = count - 1;
        if (maximumLines && (lastIndex >= maximumLines))
            lastIndex = maximumLines - 1;
        
        CTLineRef lastLine = (__bridge CTLineRef)[lines objectAtIndex:lastIndex];
        CFRange lastLineRange = CTLineGetStringRange(lastLine);
        desiredRange = CFRangeMake(0, lastLineRange.location + lastLineRange.length);
    }
    
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, desiredRange, NULL, constraint, NULL);
    
    // round to integral points
    return CGSizeMake(ceil(textSize.width + VELLabelPadding * 2), ceil(textSize.height + VELLabelPadding * 2));
}

#pragma mark Formatting

- (void)setAttribute:(NSString *)attributeName value:(id)value; {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:VELLabelEmptyAttributedString];

    if (self.formattedText)
        [attributedString setAttributedString:self.formattedText];

    NSRange range = NSMakeRange(0, attributedString.length);

    if (value)
        [attributedString addAttribute:attributeName value:value range:range];
    else
        [attributedString removeAttribute:attributeName range:range];

    self.formattedText = attributedString;
}

- (void)setParagraphStyle {
    CTLineBreakMode lineBreakMode = m_lineBreakMode;
    CTTextAlignment textAlignment = m_textAlignment;
    
    CTParagraphStyleSetting settings[] = {
        {
            .spec = kCTParagraphStyleSpecifierLineBreakMode,
            .valueSize = sizeof(lineBreakMode),
            .value = &lineBreakMode
        },
        {
            .spec = kCTParagraphStyleSpecifierAlignment,
            .valueSize = sizeof(textAlignment),
            .value = &textAlignment
        }
    };

    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(*settings));
    [self setAttribute:NSParagraphStyleAttributeName value:(__bridge_transfer id)paragraphStyle];
}

@end
