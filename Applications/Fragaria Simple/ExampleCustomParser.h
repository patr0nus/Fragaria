//
//  ExampleCustomParser.h
//  Fragaria Simple
//
//  Created by Daniele Cattaneo on 28/12/2018.
//

#import <Fragaria/Fragaria.h>

NS_ASSUME_NONNULL_BEGIN

/* This is the simplest use-case for custom parsers: a single standalone
 * parser with a single factory that exports just that parser.
 * In this case, the parser factory can be made the same object as the
 * parser itself.
 *
 * If we want to share the same parser for multiple syntax definitions,
 * it is better to have a separate parser class, whose state is set
 * depending on the language, and a single parser factory which
 * initializes each parser according to the language.
 * See the implementation of MGSClassicFragariaParserFactory for an
 * example of this use case. */

@interface ExampleCustomParser : MGSSyntaxParser <MGSParserFactory>

@end

NS_ASSUME_NONNULL_END
