//
//  VELCAAction.m
//  Velvet
//
//  Created by James Lawton on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELCAAction.h>
#import <Velvet/VELView.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/VELFocusRingLayer.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <objc/runtime.h>


@interface VELCAAction ()
/*
 * The action that this action is proxying, as specified at the time of
 * initialization.
 */
@property (nonatomic, strong, readonly) id <CAAction> innerAction;

/*
 * Invoked whenever the geometry property `key` of `layer` has changed.
 */
- (void)geometryChangedForKey:(NSString *)key layer:(CALayer *)layer;

/*
 * Returns `YES` if objects of this class add features to actions for the given
 * geometry property.
 */
+ (BOOL)interceptsGeometryActionForKey:(NSString *)key;

@end


@implementation VELCAAction
@synthesize innerAction = m_innerAction;

- (id)initWithAction:(id<CAAction>)innerAction {
    self = [super init];
    if (!self)
        return nil;

    m_innerAction = innerAction;
    return self;
}

+ (id)actionWithAction:(id<CAAction>)innerAction {
    return [[self alloc] initWithAction:innerAction];
}

- (void)enumerateVELNSViewsInLayer:(CALayer *)layer block:(void(^)(VELNSView *))block {
    if ([layer.delegate isKindOfClass:[VELNSView class]]) {
        block(layer.delegate);
    } else {
        for (CALayer *sublayer in [layer sublayers]) {
            [self enumerateVELNSViewsInLayer:sublayer block:block];
        }
    }
}

- (void)runActionForKey:(NSString *)key object:(id)anObject arguments:(NSDictionary *)dict {
    [self.innerAction runActionForKey:key object:anObject arguments:dict];
    CAAnimation *animation = [anObject animationForKey:key];
    if (!animation)
        return;

    if ([[self class] interceptsGeometryActionForKey:key]) {
        [self geometryChangedForKey:key layer:anObject];
    }
}

- (void)geometryChangedForKey:(NSString *)key layer:(CALayer *)layer {
    // For all contained VELNSViews, render their NSView into their layer
    // and hide the NSView. Now the visual element is part of the layer
    // hierarchy we're animating.
    NSMutableArray *cachedViews = [NSMutableArray array];
    [self enumerateVELNSViewsInLayer:layer block:^(VELNSView *view) {
        if (view.focusRingLayer) {
            [CATransaction performWithDisabledActions:^{
                view.focusRingLayer.opacity = 0.0f;
            }];
        }
        
        view.rendersContainedView = YES;
        view.NSView.alphaValue = 0.0;
        [cachedViews addObject:view];
    }];

    // If we did nothing, there's no cleanup needed.
    if (![cachedViews count])
        return;

    // Set up a block to return the NSViews to rendering themselves.
    void (^completionBlock)(void) = ^{
        [cachedViews enumerateObjectsUsingBlock:^(VELNSView *view, NSUInteger idx, BOOL *stop) {
            view.rendersContainedView = NO;
            [view synchronizeNSViewGeometry];

            view.NSView.alphaValue = 1.0;

            view.focusRingLayer.opacity = 1.0f;
        }];
    };

    // Schedule the cleanup to occur when this animation ends.
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)([CATransaction animationDuration] * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), completionBlock);
}

+ (BOOL)interceptsGeometryActionForKey:(NSString *)key {
    return [key isEqualToString:@"position"] || [key isEqualToString:@"bounds"] || [key isEqualToString:@"transform"];
}

+ (BOOL)interceptsActionForKey:(NSString *)key {
    return [self interceptsGeometryActionForKey:key];
}

@end

