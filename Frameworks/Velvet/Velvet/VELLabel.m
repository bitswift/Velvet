//
//  VELLabel.m
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELLabel.h>
#import <Proton/EXTScope.h>

static const CGFloat VELLabelPadding = 2.0f;

static NSString * const VELLabelEmptyAttributedString = @"\0";

static NSRange NSRangeFromCFRange(CFRange range) {
    if (range.location == kCFNotFound) {
        return NSMakeRange(NSNotFound, (NSUInteger)range.length);
    }
    else {
        return NSMakeRange((NSUInteger)range.location, (NSUInteger)range.length);
    }
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
 * Returns a new array containing all `CTLineRef` objects necessary to draw the
 * given string within the given width.
 *
 * These lines may flow over the label's height.
 *
 * @param string The string from which to create lines.
 * @param maximumWidth A width to which to constrain the lines. Use
 * `CGFLOAT_MAX` to indicate that there is no constraint upon the width.
 */
- (NSMutableArray *)linesForAttributedString:(NSAttributedString *)string constrainedToWidth:(CGFloat)maximumWidth;

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

- (NSMutableArray *)linesForAttributedString:(NSAttributedString *)string constrainedToWidth:(CGFloat)maximumWidth; {
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
    @onExit {
        CFRelease(typesetter);
    };

    CFIndex strLength = (CFIndex)string.length;
    CFIndex characterIndex = 0;
    NSMutableArray *lines = [NSMutableArray array];
    
    while (characterIndex < strLength) {
        CFIndex characterCount = 0;
        
        switch (self.lineBreakMode) {
            case VELLineBreakModeCharacterWrap:
                characterCount = CTTypesetterSuggestClusterBreak(typesetter, characterIndex, maximumWidth - VELLabelPadding * 2);
                break;

            case VELLineBreakModeClip:
                characterCount = strLength;
                break;

            case VELLineBreakModeWordWrap:
            // Truncation is treated similar to word wrap before we condense it down and add an elipsis
            case VELLineBreakModeHeadTruncation:
            case VELLineBreakModeLastLineMiddleTruncation:
            case VELLineBreakModeTailTruncation:
            default:
                characterCount = CTTypesetterSuggestLineBreak(typesetter, characterIndex, maximumWidth - VELLabelPadding * 2);
                break;
        }
        
        CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(characterIndex, characterCount));
        [lines addObject:(__bridge_transfer id)line];
        characterIndex += characterCount;
    }
    
    return lines;
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
    
    CGFloat drawableWidth = self.bounds.size.width - VELLabelPadding * 2;
    CGFloat drawableHeight = self.bounds.size.height - VELLabelPadding * 2;

    NSMutableArray *lines = [self linesForAttributedString:attributedString constrainedToWidth:drawableWidth];

    NSUInteger numberOfLinesToDraw = lines.count;
    BOOL shouldTruncate = (self.lineBreakMode == VELLineBreakModeHeadTruncation || self.lineBreakMode == VELLineBreakModeLastLineMiddleTruncation || self.lineBreakMode == VELLineBreakModeTailTruncation);
    
    // If we are truncating then we may need to adjust numberOfLinesToDraw
    if (shouldTruncate) {
        numberOfLinesToDraw = 0;
        
        // Determine if we have more lines than will fit vertically in our bounds
        CGFloat height = 0.0f;
        for (NSUInteger i = 0; i < lines.count; i++) {
            CTLineRef aLine = (__bridge CTLineRef)[lines objectAtIndex:i];
            
            CGFloat ascent;
            CGFloat descent;
            CGFloat leading;
            CTLineGetTypographicBounds(aLine, &ascent, &descent, &leading);
            
            height += ceil(ascent + descent + leading);
            
            // Only draw the line if it will fully fit in the bounds
            if (height > drawableHeight) {
                break;
            }
            numberOfLinesToDraw++;
        }
    }
    
    // If we have more lines than will fit and the label uses truncation, we'll need to cull the lines
    if (numberOfLinesToDraw == 0) {
        [lines removeAllObjects];
    } else if (numberOfLinesToDraw < lines.count) {
        NSAssert(shouldTruncate, @"Should only have a reduced number of lines if we're truncating");
        
        CFAttributedStringRef ellipsisAttributedString = CFAttributedStringCreate(NULL, (CFStringRef) @"…", NULL);
        @onExit {
            CFRelease(ellipsisAttributedString);
        };
        CTLineRef ellipsisLine = NULL;
        ellipsisLine = CTLineCreateWithAttributedString(ellipsisAttributedString);        
        @onExit {
            CFRelease(ellipsisLine);
        };
        
        if (self.lineBreakMode == VELLineBreakModeHeadTruncation) {
            // Calculate the truncated first line if we have more lines than will be drawn
            //   and the label uses VELLineBreakModeHeadTruncation
            CTLineRef firstVisibleLine = (__bridge CTLineRef)[lines objectAtIndex:lines.count - numberOfLinesToDraw];
            NSRange firstLineRange = NSRangeFromCFRange(CTLineGetStringRange(firstVisibleLine));
            // what we really want is a range from the beginning to the end of `firstVisibleLine`
            firstLineRange.length = firstLineRange.location + firstLineRange.length;
            firstLineRange.location = 0;
            
            NSAttributedString *firstLineAttrStr = [attributedString attributedSubstringFromRange:firstLineRange];
            
            CTLineRef firstLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)firstLineAttrStr);
            CTLineRef lineToDraw = CTLineCreateTruncatedLine(firstLine, drawableWidth, kCTLineTruncationStart, ellipsisLine);

            if (!lineToDraw)
                lineToDraw = firstLine;
            else
                CFRelease(firstLine);
            
            // Remove extra lines that we won't be drawing
            [lines removeObjectsInRange:NSMakeRange(0, lines.count - numberOfLinesToDraw)];

            // Replace the first line with our truncated version (transferring
            // its ownership to ARC in the same step)
            [lines replaceObjectAtIndex:0 withObject:(__bridge_transfer id)lineToDraw];
        } else {
            // Calculate the truncated last line if we have more lines than will be drawn
            //   and the label has truncation affecting the last line
            CTLineRef lastVisibleLine = (__bridge CTLineRef)[lines objectAtIndex:numberOfLinesToDraw - 1];
            NSRange lastLineRange = NSRangeFromCFRange(CTLineGetStringRange(lastVisibleLine));
            lastLineRange.length = attributedString.length - lastLineRange.location;
            
            NSAttributedString *lastLineAttrStr = [attributedString attributedSubstringFromRange:lastLineRange];
            
            CTLineTruncationType truncationType;
            switch (self.lineBreakMode) {
                case VELLineBreakModeLastLineMiddleTruncation:
                    truncationType = kCTLineTruncationMiddle;
                    break;
                case VELLineBreakModeTailTruncation:
                default:
                    truncationType = kCTLineTruncationEnd;
                    break;
            }
            
            CTLineRef lastLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)lastLineAttrStr);
            CTLineRef lineToDraw = CTLineCreateTruncatedLine(lastLine, drawableWidth, truncationType, ellipsisLine);

            if (!lineToDraw)
                lineToDraw = lastLine;
            else
                CFRelease(lastLine);
            
            // Remove extra lines that we won't be drawing
            [lines removeObjectsInRange:NSMakeRange(numberOfLinesToDraw, lines.count - numberOfLinesToDraw)];

            // Replace the last line with our truncated version (transferring
            // its ownership to ARC in the same step)
            [lines replaceObjectAtIndex:numberOfLinesToDraw - 1 withObject:(__bridge_transfer id)lineToDraw];
        }
    }
    
    // Draw all the visible lines
    CGFloat originY = 0.0f;
    for (NSUInteger i = 0; i < lines.count; i++) {
        CTLineRef aLine = (__bridge CTLineRef)[lines objectAtIndex:i];
        
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CGFloat lineWidth = CTLineGetTypographicBounds(aLine, &ascent, &descent, &leading);
        
        originY += ceil(ascent + leading);
                
        CGFloat widthOfPrintedGlyphs = lineWidth - CTLineGetTrailingWhitespaceWidth(aLine);
        CGFloat indentWidth = VELLabelPadding;
        switch (self.textAlignment) {
            case VELTextAlignmentCenter:
                indentWidth = floor((drawableWidth - widthOfPrintedGlyphs)/2.0f + VELLabelPadding);
                break;
            case VELTextAlignmentRight:
                // It is not appropriate to floor `indentWidth` when using `VELTextAlignmentRight`
                indentWidth = drawableWidth - widthOfPrintedGlyphs + VELLabelPadding;
                break;
            default:
                break;
        }
        
        CGContextSetTextPosition(context, indentWidth, (self.bounds.size.height - VELLabelPadding) - originY);
        if (i < lines.count - 1 && self.textAlignment == kCTJustifiedTextAlignment) {
            // Only create justified lines if we are NOT at the last line yet
            aLine = CTLineCreateJustifiedLine(aLine, 1.0f, drawableWidth);
            CTLineDraw(aLine, context);
            CFRelease(aLine);
        } else {
            CTLineDraw(aLine, context);
        }
        originY += descent;
    }
}

- (CGSize)sizeThatFits:(CGSize)constraint {
    NSAttributedString *string = self.formattedText;
    if (!string)
        return CGSizeZero;
    
    // subtract our padding here, we'll add it back in at the end after we figure out the text size
    constraint.width -= VELLabelPadding * 2;
    constraint.height -= VELLabelPadding * 2;

    NSArray *lines;

    // if one line, don't constrain the width (the text should be as wide as
    // necessary)
    NSUInteger maximumLines = self.numberOfLines;
    if (maximumLines == 1) {
        CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
        @onExit {
            CFRelease(typesetter);
        };

        CTLineRef fullTextLine = CTTypesetterCreateLine(typesetter, CFRangeMake(0, [string length]));
        lines = [NSArray arrayWithObject:(__bridge_transfer id)fullTextLine];
    } else { 
        lines = [self linesForAttributedString:string constrainedToWidth:constraint.width];
    }
    
    CGFloat height = 0.0f;
    CGFloat width = 0.0f;

    for (NSUInteger i = 0; i < lines.count; i++) {
        if (maximumLines > 0 && i >= maximumLines)
            break;

        CTLineRef aLine = (__bridge CTLineRef)[lines objectAtIndex:i];
        
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        width = fmax(width, CTLineGetTypographicBounds(aLine, &ascent, &descent, &leading));
        
        height += ceil(ascent + descent + leading);
    }

    return CGSizeMake(ceil(width + VELLabelPadding * 2), ceil(height + VELLabelPadding * 2));
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
    CTTextAlignment textAlignment = m_textAlignment;
    
    CTParagraphStyleSetting settings[] = {
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
