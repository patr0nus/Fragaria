//
//  MGSLineNumberViewDecoration.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 09/03/16.
//
//

#import <Cocoa/Cocoa.h>


/** A protocol for decoration objects of MGSLineNumberView. */

@protocol MGSLineNumberViewDecoration <NSObject>


/** The image to display. */
- (NSImage *)warningImage;


@end
