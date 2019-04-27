//
//  MGSStandardParser.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 27/04/2019.
//

#import <Fragaria/Fragaria.h>

NS_ASSUME_NONNULL_BEGIN


/** The parser that defines the "Standard" language.
 *
 *  The "Standard" language is a language without any colouring,
 *  without any file associations, and which is guaranteed to
 *  be available. */

@interface MGSStandardParser : MGSSyntaxParser <MGSParserFactory>


+ (NSString *)standardSyntaxDefinitionName;


@end


NS_ASSUME_NONNULL_END
