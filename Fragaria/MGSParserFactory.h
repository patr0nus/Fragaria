//
//  MGSParserFactory.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 26/12/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class MGSSyntaxParser;


/** MGSParserFactory objects are used by MGSSyntaxController to find
 *  available MGSSyntaxParser objects. Additionally, they provide
 *  metadata about the languages supported by the parsers they can instantiate. */
@protocol MGSParserFactory <NSObject>


/** The list of language identifiers provided by this object. */
@property (strong, nonatomic, readonly) NSArray *syntaxDefinitionNames;

/** Returns a MGSSyntaxParser suitable for parsing a string of the specified
 *  language.
 *  @param syndef One of the language identifiers from this object's
 *         syntaxDefinitionNames list.
 *  @returns A parser for the specified language. */
- (MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)syndef;


@optional

/** Returns a list of language identifiers corresponding to the given
 *  filename extension.
 *  @param extension The extension for which to search matching languages.
 *  @returns A list of language identifiers, subset of syntaxDefinitionNames.
 *  @note This method shall not return a language identifier not included in
 *        syntaxDefinitionNames. */
- (NSArray <NSString *> *)syntaxDefinitionNamesWithExtension:(NSString *)extension;

/** Returns a list of language identifiers corresponding to the given
 *  Universal Type Identifier (UTI).
 *  @param uti The UTI for which to search matching languages.
 *  @returns A list of language identifiers, subset of syntaxDefinitionNames.
 *  @note This method shall not return a language identifier not included in
 *        syntaxDefinitionNames. */
- (NSArray <NSString *> *)syntaxDefinitionNamesWithUTI:(NSString *)uti;

/** Returns a list of language identifiers guessed based on the first line of
 *  a text file.
 *  @param firstLine The first line of a text file.
 *  @returns A list of language identifiers, subset of syntaxDefinitionNames.
 *  @note This method shall not return a language identifier not included in
 *        syntaxDefinitionNames. */
- (NSArray <NSString *> *)guessSyntaxDefinitionNamesFromFirstLine:(NSString *)firstLine;


@end

NS_ASSUME_NONNULL_END
