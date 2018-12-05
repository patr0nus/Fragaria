//
//  MGSSyntaxParser.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 30/10/2018.
//

#import <Cocoa/Cocoa.h>
#import "MGSSyntaxParserClient.h"
#import "MGSSyntaxAwareEditor.h"
#import "SMLAutoCompleteDelegate.h"

NS_ASSUME_NONNULL_BEGIN


@class MGSSyntaxDefinition;


@interface MGSSyntaxParser : NSObject <MGSSyntaxAwareEditor, SMLAutoCompleteDelegate>


- (instancetype)initWithSyntaxDefinition:(MGSSyntaxDefinition *)sdef;

@property (nonatomic, readonly) MGSSyntaxDefinition *syntaxDefinition;

/** If multiline strings should be coloured. */
@property (nonatomic, assign) BOOL coloursMultiLineStrings;
/** If coloring should end at end of line. */
@property (nonatomic, assign) BOOL coloursOnlyUntilEndOfLine;

- (NSRange)parseString:(NSString *)string inRange:(NSRange)range forParserClient:(id<MGSSyntaxParserClient>)client;

/** The list of keywords used by autocompletion when the autoCompleteWithKeywords option
 *  is enabled. */
@property (nonatomic, readonly) NSArray <NSString *> *autocompletionKeywords;


@end


NS_ASSUME_NONNULL_END
