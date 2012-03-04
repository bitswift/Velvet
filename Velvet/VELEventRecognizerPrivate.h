//
//  VELEventRecognizerPrivate.h
//  Velvet
//
//  Created by Justin Spahr-Summers on 04.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/VELEventRecognizer.h>

/**
 * Private methods of <VELEventRecognizer> that need to be exposed to other
 * parts of the framework.
 */
@interface VELEventRecognizer (Private)
/**
 * Returns an array containing all event recognizers attached to the given
 * layer. If no such recognizers exist, returns `nil`.
 *
 * An event recognizer becomes attached to a layer when its <[VELEventRecognizer
 * view]> is set.
 *
 * @param layer A layer to return the attached event recognizers for.
 */
+ (NSArray *)eventRecognizersForLayer:(CALayer *)layer;

/**
 * Contains any events that the receiver should ignore.
 *
 * This is filled in with delayed events by the event recognizer. When
 * <VELEventManager> sees any objects in this array come through, it avoids
 * dispatching them to the receiver, and will remove them from the set at that
 * point.
 */
@property (nonatomic, strong, readonly) NSMutableSet *eventsToIgnore;
@end
