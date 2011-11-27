//
//  VELScrollView.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 27.11.11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELScrollView.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <Velvet/VELNSView.h>
#import <Velvet/VELViewProtected.h>
#import <QuartzCore/QuartzCore.h>

/*
 * The duration, in seconds, for which scrollers stay visible after a scrolling
 * event.
 */
static const NSTimeInterval VELScrollViewScrollersVisibleDuration = 0.65;

@interface VELScrollView ()
/*
 * The layer which will contain any subviews, responsible for scrolling and
 * clipping them.
 */
@property (nonatomic, strong, readonly) CAScrollLayer *scrollLayer;

/*
 * Contains a horizontal `NSScroller`.
 */
@property (nonatomic, strong, readonly) VELNSView *horizontalScrollerHost;

/*
 * Contains a vertical `NSScroller`.
 */
@property (nonatomic, strong, readonly) VELNSView *verticalScrollerHost;

/*
 * Whether the scrollers are currently being shown.
 */
@property (nonatomic, assign) BOOL scrollersVisible;

/*
 * Invoked when one of the scrollers moves.
 */
- (void)scrolled:(NSScroller *)sender;

/*
 * Scrolls the underlying layer to the specified point and notifies all
 * subviews.
 */
- (void)scrollToPoint:(CGPoint)point;
@end

@implementation VELScrollView

#pragma mark Properties

@synthesize scrollLayer = m_scrollLayer;
@synthesize horizontalScrollerHost = m_horizontalScrollerHost;
@synthesize verticalScrollerHost = m_verticalScrollerHost;
@synthesize scrollersVisible = m_scrollersVisible;

- (NSScroller *)horizontalScroller {
    return (id)self.horizontalScrollerHost.NSView;
}

- (NSScroller *)verticalScroller {
    return (id)self.verticalScrollerHost.NSView;
}

- (CGSize)contentSize {
    return self.scrollLayer.contentsRect.size;
}

- (void)setContentSize:(CGSize)contentSize {
    self.scrollLayer.contentsRect = CGRectMake(0, 0, contentSize.width, contentSize.height);
}

- (void)setSubviews:(NSArray *)subviews {
    // keep our scroller host views at the end
    BOOL (^isScroller)(VELView *) = ^ BOOL (VELView *view){
        return view == self.horizontalScrollerHost || view == self.verticalScrollerHost;
    };

    subviews = [subviews sortedArrayWithOptions:NSSortStable usingComparator:^ NSComparisonResult (VELView *viewA, VELView *viewB){
        if (isScroller(viewA)) {
            if (isScroller(viewB)) {
                return NSOrderedSame;
            } else {
                return NSOrderedDescending;
            }
        } else if (isScroller(viewB)) {
            return NSOrderedAscending;
        }

        return NSOrderedSame;
    }];
    
    [super setSubviews:subviews];
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    // we don't even provide a setter for these ivars, because they should never
    // change after initialization
    
    m_scrollLayer = [[CAScrollLayer alloc] init];
    m_scrollLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    m_scrollLayer.delegate = self;
    m_scrollLayer.layoutManager = self;
    [self.layer addSublayer:m_scrollLayer];

    self.layer.masksToBounds = YES;

    // TODO: subscribe to notifications about preferred scroller style changing?
    NSScrollerStyle style = [NSScroller preferredScrollerStyle];
    CGFloat scrollerWidth = [NSScroller scrollerWidthForControlSize:NSRegularControlSize scrollerStyle:style];

    NSScroller *(^preparedScrollerWithSize)(CGSize) = ^(CGSize size){
        NSScroller *scroller = [[NSScroller alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)];

        scroller.target = self;
        scroller.action = @selector(scrolled:);

        scroller.scrollerStyle = style;
        scroller.enabled = YES;
        scroller.alphaValue = 0;

        scroller.knobProportion = 1;
        scroller.doubleValue = 0;
        return scroller;
    };

    m_horizontalScrollerHost = [[VELNSView alloc] initWithNSView:preparedScrollerWithSize(CGSizeMake(100, scrollerWidth))];
    m_verticalScrollerHost = [[VELNSView alloc] initWithNSView:preparedScrollerWithSize(CGSizeMake(scrollerWidth, 100))];

    self.subviews = [NSArray arrayWithObjects:m_horizontalScrollerHost, m_verticalScrollerHost, nil];
    self.verticalScroller.doubleValue = 1;

    return self;
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark View hierarchy

- (void)addSubviewToLayer:(VELView *)view; {
    // play nicely with the scrollers -- use the default behavior
    if (view == m_horizontalScrollerHost || view == m_verticalScrollerHost) {
        [super addSubviewToLayer:view];
        return;
    }

    [self.scrollLayer addSublayer:view.layer];
}

- (id)ancestorScrollView; {
    return self;
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    CGRect contentRect = self.scrollLayer.contentsRect;

    CGFloat horizontalScrollerHeight = self.horizontalScroller.bounds.size.height;
    CGFloat verticalScrollerWidth = self.verticalScroller.bounds.size.width;

    self.horizontalScrollerHost.frame = CGRectMake(0, 0, bounds.size.width - verticalScrollerWidth, self.horizontalScrollerHost.bounds.size.height);
    self.horizontalScroller.knobProportion = CGRectGetWidth(bounds) / CGRectGetWidth(contentRect);

    self.verticalScrollerHost.frame = CGRectMake(bounds.size.width - verticalScrollerWidth, horizontalScrollerHeight, verticalScrollerWidth, bounds.size.height - horizontalScrollerHeight);
    self.verticalScroller.knobProportion = CGRectGetHeight(bounds) / CGRectGetHeight(contentRect);
}

- (void)scrollToPoint:(CGPoint)point; {
    if (self.scrollersVisible) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutScrollers) object:nil];
    } else {
        NSView *horizontalScrollerAnimator = self.horizontalScroller.animator;
        NSView *verticalScrollerAnimator = self.verticalScroller.animator;

        [NSAnimationContext beginGrouping];
        horizontalScrollerAnimator.alphaValue = 1;
        verticalScrollerAnimator.alphaValue = 1;
        [NSAnimationContext endGrouping];

        self.scrollersVisible = YES;
    }

    [CATransaction performWithDisabledActions:^{
        [self.scrollLayer scrollToPoint:point];
    }];

    CGSize contentSize = self.scrollLayer.contentsRect.size;
    self.horizontalScroller.doubleValue = point.x / contentSize.width;
    self.verticalScroller.doubleValue = 1.0 - point.y / contentSize.height;

    for (VELView *view in self.subviews) {
        [view ancestorDidScroll];
    }

    [self performSelector:@selector(fadeOutScrollers) withObject:nil afterDelay:VELScrollViewScrollersVisibleDuration];
}

#pragma mark Events

- (void)scrolled:(NSScroller *)sender; {
    CGSize contentSize = self.scrollLayer.contentsRect.size;

    CGFloat scrollX = round(self.horizontalScroller.doubleValue * contentSize.width);
    CGFloat scrollY = round(contentSize.height - self.verticalScroller.doubleValue * contentSize.height);
    [self scrollToPoint:CGPointMake(scrollX, scrollY)];
}

- (void)scrollWheel:(NSEvent *)event; {
    CGPoint currentScrollPoint = self.scrollLayer.bounds.origin;
    CGSize contentSize = self.scrollLayer.contentsRect.size;

    CGFloat scrollX = fmax(0, fmin(contentSize.width , round(currentScrollPoint.x - event.scrollingDeltaX)));
    CGFloat scrollY = fmax(0, fmin(contentSize.height, round(currentScrollPoint.y + event.scrollingDeltaY)));
    [self scrollToPoint:CGPointMake(scrollX, scrollY)];
}

#pragma mark Animations

- (void)fadeOutScrollers {
    NSView *horizontalScrollerAnimator = self.horizontalScroller.animator;
    NSView *verticalScrollerAnimator = self.verticalScroller.animator;

    [NSAnimationContext beginGrouping];
    horizontalScrollerAnimator.alphaValue = 0;
    verticalScrollerAnimator.alphaValue = 0;
    [NSAnimationContext endGrouping];

    self.scrollersVisible = NO;
}

#pragma mark CALayer delegate

- (void)displayLayer:(CALayer *)layer {
}

@end
