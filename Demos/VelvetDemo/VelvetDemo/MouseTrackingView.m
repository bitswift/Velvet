//
//  MouseTrackingView.m
//  VelvetDemo
//
//  Created by James Lawton on 2/9/12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "MouseTrackingView.h"


@interface MouseTrackingView ()
@property (nonatomic, assign, getter = isHover) BOOL hover;
@property (nonatomic, strong, readonly) CALayer *mouseDotLayer;
@end


@implementation MouseTrackingView

@synthesize normalColor = m_normalColor;
@synthesize hoverColor = m_hoverColor;
@synthesize dotColor = m_dotColor;
@synthesize hover = m_hover;
@synthesize mouseDotLayer = m_mouseDotLayer;

- (NSColor *)normalColor {
    return m_normalColor ?: [NSColor grayColor];
}

- (NSColor *)hoverColor {
    return m_hoverColor ?: [NSColor greenColor];
}

- (NSColor *)dotColor {
    if (!m_dotColor)
        m_dotColor = [NSColor redColor];
    return m_dotColor;
}

- (void)setDotColor:(NSColor *)dotColor {
    m_dotColor = dotColor;
    self.mouseDotLayer.backgroundColor = self.dotColor.CGColor;
}

- (void)setHover:(BOOL)hover {
    m_hover = hover;
    [self setNeedsDisplay];
}

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    m_mouseDotLayer = [CALayer layer];
    m_mouseDotLayer.bounds = CGRectMake(0, 0, 15, 15);
    m_mouseDotLayer.backgroundColor = self.dotColor.CGColor;
    [self.layer addSublayer:m_mouseDotLayer];

    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;

    if (self.hover) {
        CGContextSetFillColorWithColor(context, self.hoverColor.CGColor);
    } else {
        CGContextSetFillColorWithColor(context, self.normalColor.CGColor);
    }

    CGContextFillRect(context, self.bounds);
}

- (void)mouseEntered:(NSEvent *)event {
    self.hover = YES;
}

- (void)mouseMoved:(NSEvent *)event {
    CGPoint pos = [self convertFromWindowPoint:event.locationInWindow];
    [CATransaction performWithDisabledActions:^{
        self.mouseDotLayer.position = CGPointAdd(CGPointFloor(pos), CGPointMake(0.5, 0.5));
    }];
}

- (void)mouseExited:(NSEvent *)event {
    self.hover = NO;
}

@end
