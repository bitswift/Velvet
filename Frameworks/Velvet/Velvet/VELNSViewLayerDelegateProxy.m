//
//  VELNSViewLayerDelegateProxy.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 16.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELNSViewLayerDelegateProxy.h>

@interface VELNSViewLayerDelegateProxy () {
    /*
     * The original layer delegate (i.e., the one being proxied).
     *
     * This object is strongly retained, since we cannot form weak references to
     * some AppKit classes, and simply not retaining it would be highly
     * dangerous.
     */
    id m_originalDelegate;

    /*
     * An array of delegate proxies for the sublayers of the original layer.
     *
     * This is necessary to prevent implicit animations from occurring
     * _anywhere_ in the tree.
     */
    NSArray *m_sublayerDelegateProxies;
}

/*
 * Creates or removes objects in <m_sublayerDelegateProxies> to match the
 * sublayers of the given layer.
 *
 * @param layer The layer for which the receiver is the delegate.
 */
- (void)updateSublayerDelegateProxiesWithLayer:(CALayer *)layer;

@end

@implementation VELNSViewLayerDelegateProxy

#pragma mark Lifecycle

+ (id)layerDelegateProxyWithLayer:(CALayer *)layer; {
    NSParameterAssert(layer != nil);
    NSParameterAssert(layer.delegate != nil);

    // NSProxy does not provide an 'init' method, and we don't want to conflict
    // with any message forwarding, so we fill in ivars from here
    VELNSViewLayerDelegateProxy *proxy = [VELNSViewLayerDelegateProxy alloc];

    proxy->m_originalDelegate = layer.delegate;
    [proxy updateSublayerDelegateProxiesWithLayer:layer];

    layer.delegate = proxy;
    return proxy;
}

- (void)dealloc {
    m_originalDelegate = nil;
}

#pragma mark Sublayers

- (void)updateSublayerDelegateProxiesWithLayer:(CALayer *)layer; {
    if (!layer.sublayers) {
        m_sublayerDelegateProxies = nil;
        return;
    }

    NSMutableArray *newProxies = [[NSMutableArray alloc] initWithCapacity:layer.sublayers.count];

    for (CALayer *sublayer in layer.sublayers) {
        if (!sublayer.delegate)
            continue;

        NSUInteger existingProxyIndex = [m_sublayerDelegateProxies indexOfObjectIdenticalTo:sublayer.delegate];
        VELNSViewLayerDelegateProxy *proxy;

        if (existingProxyIndex == NSNotFound) {
            proxy = [VELNSViewLayerDelegateProxy layerDelegateProxyWithLayer:sublayer];
        } else {
            proxy = sublayer.delegate;
        }

        [newProxies addObject:proxy];
    }

    m_sublayerDelegateProxies = newProxies;
}

#pragma mark CALayer delegate

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)key {
    BOOL mightBeChangingSublayers = [key isEqualToString:@"sublayers"] || [key isEqualToString:kCAOnOrderIn] || [key isEqualToString:kCAOnOrderOut] || [key isEqualToString:kCATransition];

    if (mightBeChangingSublayers) {
        [self updateSublayerDelegateProxiesWithLayer:layer];
    }

    return (id)[NSNull null];
}

#pragma mark Forwarding

- (id)forwardingTargetForSelector:(SEL)selector {
    return m_originalDelegate;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [m_originalDelegate methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:m_originalDelegate];
}

#pragma mark NSObject protocol

- (Class)class {
    return [m_originalDelegate class];
}

- (BOOL)conformsToProtocol:(Protocol *)protocol {
    return [m_originalDelegate conformsToProtocol:protocol];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<VELNSViewLayerDelegateProxy: %p object: %@>", (__bridge void *)self, m_originalDelegate];
}

- (NSUInteger)hash {
    return [m_originalDelegate hash];
}

- (BOOL)isEqual:(id)obj {
    return [m_originalDelegate isEqual:obj];
}

- (BOOL)isKindOfClass:(Class)class {
    return [m_originalDelegate isKindOfClass:class];
}

- (BOOL)isMemberOfClass:(Class)class {
    return [m_originalDelegate isMemberOfClass:class];
}

- (BOOL)respondsToSelector:(SEL)selector {
    if (selector == @selector(actionForLayer:forKey:)) {
        return YES;
    }

    return [m_originalDelegate respondsToSelector:selector];
}

- (Class)superclass {
    return [m_originalDelegate superclass];
}

@end
