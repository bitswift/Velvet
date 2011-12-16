//
//  VELLabel.m
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELLabel.h>
#import <Proton/EXTScope.h>

static NSString * const VELLabelEmptyAttributedString = @"\0";

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

    if (!text)
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

    return self;
}


#pragma mark Line Calculations

- (NSArray *)linesToDraw {
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.formattedText);
    CFIndex strLength = (CFIndex)self.formattedText.length;
    CFIndex characterIndex = 0;
    NSMutableArray *lines = [NSMutableArray array];
    while (characterIndex < strLength - 1) {
        CFIndex characterCount = 0;
        switch (self.lineBreakMode) {
            case VELLineBreakModeCharacterWrap:
                characterCount = CTTypesetterSuggestClusterBreak(typesetter, characterIndex, self.bounds.size.width);
                break;
            case VELLineBreakModeClip:
                characterCount = strLength;
                break;
            case VELLineBreakModeWordWrap:
            // truncation is treated similar to word wrap before we condense it down and add an elipsis
            case VELLineBreakModeHeadTruncation:
            case VELLineBreakModeMiddleTruncation:
            case VELLineBreakModeTailTruncation:
            default:
                characterCount = CTTypesetterSuggestLineBreak(typesetter, characterIndex, self.bounds.size.width);
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
    
    CGFloat requiredHeight = 0.0f;
    NSUInteger i;
    for (i = 0; i < lines.count; i++) {
        CTLineRef aLine = (__bridge CTLineRef)[lines objectAtIndex:i];
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CTLineGetTypographicBounds(aLine, &ascent, &descent, &leading);
        requiredHeight += ceil(ascent + descent + leading);
    }
    
    if (requiredHeight > self.bounds.size.height) {
        // we may need to consolodate lines depending on the lineBreakMode
        
        
        
    }
    
    CGFloat originY = 0.0f;
    for (i = 0; i < lines.count; i++) {
        CTLineRef aLine = (__bridge CTLineRef)[lines objectAtIndex:i];
        
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CTLineGetTypographicBounds(aLine, &ascent, &descent, &leading);
        
        originY += ceil(ascent + descent + leading);
        
        CGFloat indentWidth = 0.0f;
        CGContextSetTextPosition(context, indentWidth, self.bounds.size.height - originY);
        CTLineDraw(aLine, context);
    }

    
//    CFIndex strLength = (CFIndex)attributedString.length;
//    NSUInteger lineIndex = 0;
//    CFIndex characterIndex = 0;
//    CGFloat originY = 0.0f;
//    while (characterIndex < strLength - 1) {
//        CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
//        CFIndex characterCount;
//        if (self.lineBreakMode == VELLineBreakModeCharacterWrap) {
//            characterCount = CTTypesetterSuggestClusterBreak(typesetter, characterIndex, self.bounds.size.width);
//        } else if (self.lineBreakMode == VELLineBreakModeClip) {
//            characterCount = strLength;
//        } else {
//            characterCount = CTTypesetterSuggestLineBreak(typesetter, characterIndex, self.bounds.size.width);
//        }
//        CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(characterIndex, strLength - characterIndex));
//        CGFloat ascent;
//        CGFloat descent;
//        CGFloat leading;
//        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
//        CGFloat lineHeight = ceil(ascent + descent + leading + 1);
//        
//        // If we have enough vertical height to draw a line after this one
//        // OR
//        //   we are on the last line
//        //   and have some sort of truncation set
//        //   and we will have characters left over after the ones we're about to draw for this line
//        // THEN 
//        //     we need to truncate the remaining text
//        if (originY + lineHeight + lineHeight > self.bounds.size.height ||
//            (lineIndex == self.numberOfLines - 1 && 
//            (self.lineBreakMode == VELLineBreakModeHeadTruncation ||
//             self.lineBreakMode == VELLineBreakModeMiddleTruncation ||
//             self.lineBreakMode == VELLineBreakModeTailTruncation) &&
//            characterIndex + characterCount < strLength)) {
//            line = CTTypesetterCreateLine(typesetter, CFRangeMake(characterIndex, strLength - characterIndex));
//            CTLineRef ellipsis = NULL;
//            UniChar elip = 0x2026;
//            CFStringRef elipString = CFStringCreateWithCharacters(NULL, &elip, 1);
//            CFAttributedStringRef elipAttrString = CFAttributedStringCreate(NULL, elipString, NULL);
//            ellipsis = CTLineCreateWithAttributedString(elipAttrString);
//            
//            CTLineTruncationType lineTruncation = kCTLineTruncationEnd;
//            switch (self.lineBreakMode) {
//                case VELLineBreakModeHeadTruncation:
//                    // not yet supported
////                    lineTruncation = kCTLineTruncationStart;
//                    break;
//                case VELLineBreakModeMiddleTruncation:
//                    lineTruncation = kCTLineTruncationMiddle;
//                    break;
//                case VELLineBreakModeTailTruncation:
//                default:
//                    lineTruncation = kCTLineTruncationEnd;
//                    break;
//            }
//            
//            line = CTLineCreateTruncatedLine(line, self.bounds.size.width, lineTruncation, ellipsis);
//            characterIndex = strLength;
//            
//            CFRelease(elipString);
//            CFRelease(elipAttrString);
//            CFRelease(ellipsis);
//        } else {
//            line = CTTypesetterCreateLine(typesetter, CFRangeMake(characterIndex, characterCount));
//        }
//        
//        CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
//        CGFloat whitespaceWidth = CTLineGetTrailingWhitespaceWidth(line);
//         // we seem to need 1 more px for some reason
//        originY += ceil(ascent + descent + leading + 1);
//        
//        CGFloat indentWidth = 0.0f;
//        switch (self.textAlignment) {
//            case VELTextAlignmentCenter:
//                indentWidth = (self.bounds.size.width - (lineWidth - whitespaceWidth))/2.0f;
//                break;
//            case VELTextAlignmentRight:
//                indentWidth = self.bounds.size.width - lineWidth + whitespaceWidth;
//                break;                
//            case VELTextAlignmentLeft:
//            case VELTextAlignmentJustified:
//            default:
//                // keep at 0.0f
//                break;
//        }
//        
//        CGContextSetTextPosition(context, indentWidth, self.bounds.size.height - originY);
//        // only create a justified line if there are more characters to draw after this line
//        //   and the textAlignment is set to be justified
//        if (characterIndex + characterCount < strLength - 1 && self.textAlignment == VELTextAlignmentJustified) {
//            line = CTLineCreateJustifiedLine(line, 1.0f, self.bounds.size.width);
//        }
//        CTLineDraw(line, context);
//
//        characterIndex += characterCount;
//        lineIndex++;
//    }
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
    return CGSizeMake(ceil(textSize.width), ceil(textSize.height));
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
