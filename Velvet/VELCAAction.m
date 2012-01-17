//
//  VELCAAction.m
//  Velvet
//
//  Created by James Lawton on 11/21/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/VELCAAction.h>
#import <Velvet/VELView.h>
#import <Velvet/VELNSViewPrivate.h>
#import <Velvet/CATransaction+BlockAdditions.h>
#import <objc/runtime.h>

@interface VELCAAction ()
/*
 * The action that this action is proxying, as specified at the time of
 * initialization.
 */
@property (nonatomic, strong, readonly) id <CAAction> innerAction;

/*
 * The first responder when the animation began, to be restored when the
 * animation completes.
 */
@property (nonatomic, strong) NSResponder *originalFirstResponder;

/*
 * Invoked whenever the geometry property `key` of `layer` has changed.
 */
- (void)geometryChangedForKey:(NSString *)key layer:(CALayer *)layer;

/*
 * Invoked whenever the opacity of `layer` has changed.
 */
- (void)opacityChangedForLayer:(CALayer *)layer;

/*
 * Renders the `NSView` of the given view into its layer and hides the `NSView`.
 *
 * This can be used to capture a static rendering of the `NSView` for animation
 * or other purposes.
 *
 * @param view The <VELNSView> hosting the `NSView`.
 *
 * @warning **Important:** <endRenderingNSViewOfView:> should be invoked
 * to restore the normal rendering of the `NSView`. Calls to these methods
 * cannot be nested.
 */
- (void)startRenderingNSViewOfView:(VELNSView *)view;

/*
 * Restores the normal rendering of the given view's `NSView` after a previous
 * call to <startRenderingNSViewOfView:>.
 *
 * @param view The <VELNSView> hosting the `NSView`.
 *
 * @warning **Important:** Calls to this method cannot be nested.
 */
- (void)endRenderingNSViewOfView:(VELNSView *)view;

/*
 * Schedules the given block to execute when the animation of the current
 * `CATransaction` completes.
 */
- (void)runWhenAnimationCompletes:(void (^)(void))block;

/*
 * Returns `YES` if objects of this class add features to actions for the given
 * geometry property.
 */
+ (BOOL)interceptsGeometryActionForKey:(NSString *)key;

@end

@implementation VELCAAction

#pragma mark Properties

@synthesize innerAction = m_innerAction;
@synthesize originalFirstResponder = m_originalFirstResponder;

#pragma mark Lifecycle

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

#pragma mark VELNSView support

- (void)enumerateVELNSViewsInLayer:(CALayer *)layer block:(void(^)(VELNSView *))block {
    if ([layer.delegate isKindOfClass:[VELNSView class]]) {
        block(layer.delegate);
    } else {
        for (CALayer *sublayer in [layer sublayers]) {
            [self enumerateVELNSViewsInLayer:sublayer block:block];
        }
    }
}

- (void)startRenderingNSViewOfView:(VELNSView *)view; {
    // Resign first responder on an animating NSView
    // to disable focus ring.
    id responder = view.window.firstResponder;
    if ([responder isKindOfClass:[NSView class]] && [responder isDescendantOf:view.guestView]) {
        // find the next responder which is not in this NSView hierarchy, and
        // make that the first responder for the duration of the animation
        id nextResponder = [responder nextResponder];

        BOOL (^validResponder)(id) = ^(id obj){
            if (!obj)
                return YES;

            if ([obj isKindOfClass:[NSView class]] && [responder isDescendantOf:view.guestView])
                return NO;

            if (![obj acceptsFirstResponder])
                return NO;

            return YES;
        };

        while (!validResponder(nextResponder)) {
            nextResponder = [nextResponder nextResponder];
        }

        if ([view.window makeFirstResponder:nextResponder]) {
            self.originalFirstResponder = responder;
        }
    }

    view.rendersContainedView = YES;
    view.guestView.alphaValue = 0.0;
}

- (void)endRenderingNSViewOfView:(VELNSView *)view; {
    view.rendersContainedView = NO;
    [view synchronizeNSViewGeometry];

    view.guestView.alphaValue = 1.0;

    if (self.originalFirstResponder) {
        [view.window makeFirstResponder:self.originalFirstResponder];
        self.originalFirstResponder = nil;
    }
}

#pragma mark Action interception

- (void)runActionForKey:(NSString *)key object:(id)anObject arguments:(NSDictionary *)dict {
    [self.innerAction runActionForKey:key object:anObject arguments:dict];
    CAAnimation *animation = [anObject animationForKey:key];
    if (!animation)
        return;

    if ([key isEqualToString:@"opacity"]) {
        [self opacityChangedForLayer:anObject];
    } else if ([[self class] interceptsGeometryActionForKey:key]) {
        [self geometryChangedForKey:key layer:anObject];
    }
}

+ (BOOL)interceptsGeometryActionForKey:(NSString *)key {
    return [key isEqualToString:@"position"] || [key isEqualToString:@"bounds"] || [key isEqualToString:@"transform"];
}

+ (BOOL)interceptsActionForKey:(NSString *)key {
    return [key isEqualToString:@"opacity"] || [self interceptsGeometryActionForKey:key];
}

#pragma mark Action handlers

- (void)geometryChangedForKey:(NSString *)key layer:(CALayer *)layer {
    // For all contained VELNSViews, render their NSView into their layer
    // and hide the NSView. Now the visual element is part of the layer
    // hierarchy we're animating.
    NSMutableArray *cachedViews = [NSMutableArray array];
    [self enumerateVELNSViewsInLayer:layer block:^(VELNSView *view) {
        [self startRenderingNSViewOfView:view];
        [cachedViews addObject:view];
    }];

    // If we did nothing, there's no cleanup needed.
    if (![cachedViews count])
        return;

    // return NSViews to rendering themselves after this animation completes
    [self runWhenAnimationCompletes:^{
        [cachedViews enumerateObjectsUsingBlock:^(VELNSView *view, NSUInteger idx, BOOL *stop) {
            [self endRenderingNSViewOfView:view];
        }];
    }];
}

- (void)opacityChangedForLayer:(CALayer *)layer; {
    float newOpacity = layer.opacity;

    if (fabs(1 - newOpacity) < 0.001) {
        // return NSViews to rendering themselves after this animation completes
        [self runWhenAnimationCompletes:^{
            [self enumerateVELNSViewsInLayer:layer block:^(VELNSView *view) {
                [self endRenderingNSViewOfView:view];
            }];
        }];
    } else {
        // For all contained VELNSViews, render their NSView into their layer
        // and hide the NSView. Now the visual element is part of the layer
        // hierarchy we're animating.
        [self enumerateVELNSViewsInLayer:layer block:^(VELNSView *view) {
            [self startRenderingNSViewOfView:view];
        }];
    }
}

- (void)runWhenAnimationCompletes:(void (^)(void))block; {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)([CATransaction animationDuration] * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

@end

