//
//  MGSAbstractSyntaxColouring.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 07/07/2019.
//
/// @cond PRIVATE

#import <Cocoa/Cocoa.h>
#import "MGSSyntaxParserClient.h"

NS_ASSUME_NONNULL_BEGIN

@class MGSColourScheme;
@class MGSSyntaxParser;


@interface MGSAbstractSyntaxColouring : NSObject <MGSSyntaxParserClient>


/// @name Setting the object of coloring

/** The text storage containing the text to color.
 *  @note To be overridden in a concrete implementation. */
@property (nonatomic, readonly) NSMutableAttributedString *textStorage;


/// @name Coloring Settings

/** The parser currently used for colouring the text. */
@property (nonatomic, strong) MGSSyntaxParser *parser;

/** The colour scheme */
@property (nonatomic, strong) MGSColourScheme *colourScheme;
/** The base font to use for highlighting */
@property (nonatomic, strong) NSFont *textFont;

/** If multiline strings should be coloured. */
@property (nonatomic, assign) BOOL coloursMultiLineStrings;
/** If coloring should end at end of line. */
@property (nonatomic, assign) BOOL coloursOnlyUntilEndOfLine;


/// @name Performing Highlighting

/** Indicates the character ranges where colouring is valid. */
@property (strong, readonly) NSMutableIndexSet *inspectedCharacterIndexes;

/** Recolors the invalid characters in the specified range.
 * @param range A character range where, when this method returns, all syntax
 *              colouring will be guaranteed to be up-to-date. */
- (void)recolourRange:(NSRange)range;

/** Marks the entire text's colouring as invalid and removes all coloring
 *  attributes applied. */
- (void)invalidateAllColouring;

/** Forces a recolouring of the character range specified. The recolouring will
 * be done anew even if the specified range is already valid (wholly or in
 * part).
 * @param rangeToRecolour Indicates the range to be recoloured.
 * @return The range that was effectively coloured. The returned range always
 *         contains entirely the initial range. */
- (NSRange)recolourChangedRange:(NSRange)rangeToRecolour;


@end


NS_ASSUME_NONNULL_END
