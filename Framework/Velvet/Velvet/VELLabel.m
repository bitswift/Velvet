//
//  VELLabel.m
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELLabel.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation VELLabel

#pragma mark Properties

@synthesize text = m_text;

- (void)setText:(NSAttributedString *)str {
    m_text = [str copy];
    [self.layer setNeedsDisplay];
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;

    CGContextSetTextMatrix(context, CGAffineTransformIdentity);

    CGMutablePathRef path = CGPathCreateMutable();

    CGPathAddRect(path, NULL, self.bounds);

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.text);

    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CTFrameDraw(frame, context);

    CGPathRelease(path);
    CFRelease(framesetter);
}

@end
