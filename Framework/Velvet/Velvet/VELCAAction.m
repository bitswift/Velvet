//
//  VELCAAction.m
//  Velvet
//
//  Created by James Lawton on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELCAAction.h>
#import <Velvet/VELView.h>
#import <Velvet/VELNSView.h>
#import <objc/runtime.h>


@interface VELCAAction ()
@property (nonatomic, strong) id <CAAction> innerAction;
@end


@implementation VELCAAction
@synthesize innerAction = m_innerAction;
@synthesize delegate = m_delegate;

- (id)initWithAction:(id <CAAction>)innerAction
{
	self = [super init];
	if (self) {
		self.innerAction = innerAction;
	}
	return self;
}

+ (id)actionWithAction:(id <CAAction>)innerAction
{
	return [[self alloc] initWithAction:innerAction];
}

- (void)enumerateVELNSViewsInLayer:(CALayer *)layer block:(void(^)(VELNSView *))block
{
	if ([layer.delegate isKindOfClass:[VELNSView class]]) {
		block(layer.delegate);
	} else {
		for (CALayer *sublayer in [layer sublayers]) {
			[self enumerateVELNSViewsInLayer:sublayer block:block];
		}
	}
}

- (void)runActionForKey:(NSString *)key object:(id)anObject arguments:(NSDictionary *)dict
{
	[self.innerAction runActionForKey:key object:anObject arguments:dict];

	CAAnimation *animation = [anObject animationForKey:key];
	if (!animation)
		return;

	if ([key isEqualToString:@"position"] || [key isEqualToString:@"bounds"]) {

		NSMutableArray *cachedViews = [NSMutableArray array];
		[self enumerateVELNSViewsInLayer:anObject block:^(VELNSView *view) {
			[cachedViews addObject:view];
		}];

	if (![cachedViews count]) return;

//		void (^oldCompletionBlock)(void) = [CATransaction completionBlock];
		void (^completionBlock)(void) = ^{
			[cachedViews enumerateObjectsUsingBlock:^(VELNSView *view, NSUInteger idx, BOOL *stop) {
				[view NSView].alphaValue = 1;
			}];

//			if (oldCompletionBlock) oldCompletionBlock();
		};

//		[CATransaction setCompletionBlock:completionBlock];

		for (VELNSView * view in cachedViews) {
			NSView *innerView = [view NSView];
			[view setNSView:innerView];
			innerView.alphaValue = 0.0;
		}

		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)([CATransaction animationDuration] * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), completionBlock);
	}
}

@end

