//
//  VELLabel.h
//  Velvet
//
//  Created by Josh Vera on 11/21/11.
//  Copyright (c) 2011 Emerald Lark. All rights reserved.
//

#import <Velvet/VELView.h>

/**
 * A simple text label.
 */
@interface VELLabel : VELView

/**
 * @name Displaying Text
 */

/**
 * The text to display in the receiver, formatted with any desired CoreText
 * attributes.
 */
@property (copy) NSAttributedString *text;
@end
