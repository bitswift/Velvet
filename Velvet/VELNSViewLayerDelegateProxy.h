//
//  VELNSViewLayerDelegateProxy.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 16.01.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * Replaces the delegate for an `NSView` hosted (directly or indirectly) in
 * a `VELNSView`, to disable the implicit animations that would otherwise occur.
 */
@interface VELNSViewLayerDelegateProxy : NSProxy

/*
 * @name Initialization
 */

/*
 * Returns a new delegate proxy, which will become the delegate of the given
 * layer.
 * 
 * @param layer The layer to become the delegate of. The existing delegate of
 * the layer will be proxied by the returned object.
 */
+ (id)layerDelegateProxyWithLayer:(CALayer *)layer;

@end
