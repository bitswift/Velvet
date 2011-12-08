//
//  VELLabel.m
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELLabel.h>
#import "EXTScope.h"

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
@end

@implementation VELLabel

#pragma mark Properties

@synthesize formattedText = m_formattedText;
@synthesize numberOfLines = m_numberOfLines;
@synthesize lineBreakMode = m_lineBreakMode;

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

    CGMutablePathRef path = CGPathCreateMutable();
    @onExit {
        CGPathRelease(path);
    };

    CGPathAddRect(path, NULL, self.bounds);

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    @onExit {
        CFRelease(framesetter);
    };

    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    @onExit {
        CFRelease(frame);
    };

    CTFrameDraw(frame, context);
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

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.formattedText);
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
    
    CTParagraphStyleSetting settings[] = {
        {
            .spec = kCTParagraphStyleSpecifierLineBreakMode,
            .valueSize = sizeof(lineBreakMode),
            .value = &lineBreakMode
        }
    };

    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(*settings));
    [self setAttribute:NSParagraphStyleAttributeName value:(__bridge_transfer id)paragraphStyle];
}

@end
