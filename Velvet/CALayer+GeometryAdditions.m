//
//  CALayer+GeometryAdditions.m
//  Velvet
//
//  Created by Josh Vera on 11/26/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Velvet/CALayer+GeometryAdditions.h>
#import "EXTSafeCategory.h"

static CGRect convertAndClipRectFromSuperlayers (CGRect rect, CALayer *layer);

static CGRect convertAndClipRectFromSuperlayers (CGRect rect, CALayer *layer) {
    CALayer *superlayer = layer.superlayer;
    if (superlayer) {
        rect = convertAndClipRectFromSuperlayers(rect, superlayer);
        if (CGRectIsNull(rect))
            return CGRectNull;

        rect = [layer convertRect:rect fromLayer:superlayer];
    }

    if (layer.masksToBounds) {
        rect = CGRectIntersection(rect, layer.bounds);
    }

    return rect;
}

@safecategory(CALayer, GeometryAdditions)
- (CGRect)convertAndClipRect:(CGRect)rect toLayer:(CALayer *)layer {
    CALayer *clippingLayer = self.superlayer;
    CALayer *lastLayer = self;
    while (clippingLayer) {
        if (lastLayer.masksToBounds) {
            rect = CGRectIntersection(rect, lastLayer.bounds);
            if (CGRectIsNull(rect))
                return CGRectNull;
        }

        rect = [clippingLayer convertRect:rect fromLayer:lastLayer];

        lastLayer = clippingLayer;
        clippingLayer = clippingLayer.superlayer;
    }

    // 'rect' is in the coordinate system of the root layer, and has been
    // clipped accordingly

    return convertAndClipRectFromSuperlayers(rect, layer);
}

- (CGRect)convertAndClipRect:(CGRect)rect fromLayer:(CALayer *)layer {
    return [layer convertAndClipRect:rect toLayer:self];
}

@end
