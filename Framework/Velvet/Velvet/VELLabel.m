//
//  VELLabel.m
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELLabel.h>
#import <Velvet/dispatch+SynchronizationAdditions.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Velvet/VELContext.h>

@implementation VELLabel

#pragma mark Properties

@synthesize text = m_text;

- (NSAttributedString *)text {
    __block NSAttributedString *str = nil;

    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        str = [m_text copy];
    });

    return str;
}

- (void)setText:(NSAttributedString *)str {
    dispatch_sync_recursive(self.context.dispatchQueue, ^{
        m_text = [str copy];
        [self.layer setNeedsDisplay];
    });
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
