//
//  CGContext+CoreAnimationAdditions.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 11.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "CGContext+CoreAnimationAdditions.h"
#import "CGBitmapContext+PixelFormatAdditions.h"
#import "CGGeometry+ConvenienceAdditions.h"
#import "EXTScope.h"

/**
 * Clips the given context using a rendering of the given layer.
 *
 * @param context The context whose clipping path should be modified.
 * @param maskLayer A layer which functions like a mask.
 */
static void CGContextClipToLayer (CGContextRef context, CALayer *maskLayer) {
    CGContextRef maskContext = CGBitmapContextCreateGeneric(maskLayer.bounds.size, YES);
    if (!maskContext)
        return;

    @onExit {
        CGContextRelease(maskContext);
    };

    [maskLayer renderInContext:maskContext];
    
    CGImageRef maskImage = CGBitmapContextCreateImage(maskContext);
    if (!maskImage)
        return;

    @onExit {
        CGImageRelease(maskImage);
    };

    CGContextClipToMask(context, maskLayer.bounds, maskImage);
}

void CGContextDrawCALayer (CGContextRef context, CALayer *layer) {
    NSCParameterAssert(context);
    NSCParameterAssert(layer);

    if (layer.hidden)
        return;

    if (layer.shouldRasterize) {
        // if the layer wants rasterization, use -renderInContext: for it and
        // all its sublayers for the same effect
        [layer renderInContext:context];
        return;
    }

    CGRect bounds = layer.bounds;

    if (layer.masksToBounds) {
        // TODO: support cornerRadius
        CGContextClipToRect(context, bounds);
    }

    if (layer.mask) {
        CGContextClipToLayer(context, layer.mask);
    }

    CGContextSetAlpha(context, layer.opacity);

    if (layer.backgroundColor) {
        CGContextSetFillColorWithColor(context, layer.backgroundColor);
        CGContextFillRect(context, bounds);
    }

    [layer displayIfNeeded];
    id contents = layer.contents;

    // if the contents of this layer is an image, assume we should composite it
    // directly to the destination
    //
    // TODO: support contentsCenter, contentsGravity, contentsRect, etc.
    if (contents && CFGetTypeID((__bridge CFTypeRef)contents) == CGImageGetTypeID()) {
        CGImageRef image = (__bridge CGImageRef)contents;
        CGContextDrawImage(context, bounds, image);
    } else if ([contents isKindOfClass:[NSImage class]]) {
        NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
        NSRect proposedRect = bounds;

        CGImageRef image = [contents CGImageForProposedRect:&proposedRect context:nsContext hints:nil];
        CGContextDrawImage(context, proposedRect, image);
    } else {
        // otherwise, draw by hand
        [layer drawInContext:context];
    }

    if (layer.borderWidth && layer.borderColor) {
        CGContextSetStrokeColorWithColor(context, layer.borderColor);

        CGFloat lineWidth = layer.borderWidth;
        CGContextSetLineWidth(context, lineWidth);
        
        // make the line into an inset border
        //
        // TODO: support cornerRadius
        CGRect borderFrame = bounds;
        borderFrame = CGRectChop(borderFrame, ceil(lineWidth / 2), CGRectMinXEdge);
        borderFrame = CGRectChop(borderFrame, ceil(lineWidth / 2), CGRectMinYEdge);
        borderFrame = CGRectChop(borderFrame, floor(lineWidth / 2), CGRectMaxXEdge);
        borderFrame = CGRectChop(borderFrame, floor(lineWidth / 2), CGRectMaxYEdge);

        CGContextStrokeRect(context, borderFrame);
    }

    // sort layers by zPosition (but stably, such that layers with the same
    // zPosition retain their relative positions in the array)
    NSArray *orderedSublayers = [layer.sublayers
        sortedArrayWithOptions:NSSortConcurrent | NSSortStable
        usingComparator:^ NSComparisonResult (CALayer *left, CALayer *right){
            CGFloat delta = left.zPosition - right.zPosition;

            if (fabs(delta) < 0.000001)
                return NSOrderedSame;
            else if (delta < 0)
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }
    ];

    CGAffineTransform transform = CGAffineTransformIdentity;
    if (CATransform3DIsAffine(layer.sublayerTransform))
        transform = CATransform3DGetAffineTransform(layer.sublayerTransform);

    for (CALayer *sublayer in orderedSublayers) {
        CGContextSaveGState(context);
        @onExit {
            CGContextRestoreGState(context);
        };

        // this will sort of take into account the sublayer's own transform,
        // since it's implied in the frame
        //
        // TODO: support more complex transforms, position, and anchorPoint
        CGPoint frameOrigin = sublayer.frame.origin;
        CGAffineTransform transformToSublayer = CGAffineTransformTranslate(transform, frameOrigin.x, frameOrigin.y);

        CGContextConcatCTM(context, transformToSublayer);
        CGContextDrawCALayer(context, sublayer);
    }
}
