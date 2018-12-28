//
//  ExampleCustomParserWithComposition.h
//  Fragaria Simple
//
//  Created by Daniele Cattaneo on 28/12/2018.
//

#import <Fragaria/Fragaria.h>

NS_ASSUME_NONNULL_BEGIN

/* This parser modifies the output of an existing parser (specifically, the
 * standard Fragaria Objective-C parser), similarly to what could previously
 * be done through SMLSyntaxColouringDelegate. */

@interface ExampleCustomParserWithComposition : MGSSyntaxParser <MGSParserFactory>

@end

NS_ASSUME_NONNULL_END
