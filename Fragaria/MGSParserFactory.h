//
//  MGSParserFactory.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 26/12/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class MGSSyntaxParser;


@protocol MGSParserFactory <NSObject>


@property (strong, nonatomic, readonly) NSArray *syntaxDefinitionNames;


- (MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)syndef;


@optional

/**
 *  Return the name of a syntax definition for the given extension.
 *  @param extension The extension for which to return a syntax definition name.
 **/
- (NSArray <NSString *> *)syntaxDefinitionNamesWithExtension:(NSString *)extension;

/**
 *  Return the name of a syntax definition for the given UTI type.
 *  @param uti The UTI type for which to return a syntax definition name.
 **/
- (NSArray <NSString *> *)syntaxDefinitionNamesWithUTI:(NSString *)uti;

/**
 *  Attempts to guess the syntax definition from the first line of text.
 *  @param firstLine The sample text to use in order to guess the syntax definition.
 **/
- (NSArray <NSString *> *)guessSyntaxDefinitionNamesFromFirstLine:(NSString *)firstLine;


@end

NS_ASSUME_NONNULL_END
