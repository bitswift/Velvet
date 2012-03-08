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
 * Contains any events that the receiver should ignore.
 *
 * This is filled in with delayed events by the event recognizer. When
 * <VELEventManager> sees any objects in this array come through, it avoids
 * dispatching them to the receiver, and will remove them from the set at that
 * point.
 */
@property (nonatomic, strong, readonly) NSMutableSet *eventsToIgnore;
@end
