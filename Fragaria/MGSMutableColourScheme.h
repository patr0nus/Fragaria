//
//  MGSMutableColourScheme.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 20/09/18.
//

#import <Foundation/Foundation.h>
#import "MGSColourScheme.h"

NS_ASSUME_NONNULL_BEGIN


@interface MGSMutableColourScheme : MGSColourScheme


#pragma mark - Saving and Loading Colour Schemes
/// @name Saving and Loading Colour Schemes


/** Sets its values from a plist file.
 *  @param file The complete path and file to read.
 *  @param err Upon return, if the loading failed, contains an NSError object
 *         that describes the problem. */
- (BOOL)loadFromSchemeFileURL:(NSURL *)file error:(NSError **)err;


#pragma mark - Colour Scheme Properties
/// @name Colour Scheme Properties


/** Display name of the color scheme. */
@property (nonatomic, strong) NSString *displayName;

/** Base text color. */
@property (nonatomic, strong) NSColor *textColor;
/** Editor background color. */
@property (nonatomic, strong) NSColor *backgroundColor;
/** Syntax error background highlighting color. */
@property (nonatomic, strong) NSColor *defaultSyntaxErrorHighlightingColour;
/** Editor invisible characters color. */
@property (nonatomic, strong) NSColor *textInvisibleCharactersColour;
/** Editor current line highlight color. */
@property (nonatomic, strong) NSColor *currentLineHighlightColour;
/** Editor insertion point color. */
@property (nonatomic, strong) NSColor *insertionPointColor;
/** Syntax color for attributes. */
@property (nonatomic, strong) NSColor *colourForAttributes;
/** Syntax color for autocomplete. */
@property (nonatomic, strong) NSColor *colourForAutocomplete;
/** Syntax color for commands. */
@property (nonatomic, strong) NSColor *colourForCommands;
/** Syntax color for comments. */
@property (nonatomic, strong) NSColor *colourForComments;
/** Syntax color for instructions. */
@property (nonatomic, strong) NSColor *colourForInstructions;
/** Syntax color for keywords. */
@property (nonatomic, strong) NSColor *colourForKeywords;
/** Syntax color for numbers. */
@property (nonatomic, strong) NSColor *colourForNumbers;
/** Syntax color for strings. */
@property (nonatomic, strong) NSColor *colourForStrings;
/** Syntax color for variables. */
@property (nonatomic, strong) NSColor *colourForVariables;

/** Should attributes be colored? */
@property (nonatomic, assign) BOOL coloursAttributes;
/** Should autocomplete be colored? */
@property (nonatomic, assign) BOOL coloursAutocomplete;
/** Should commands be colored? */
@property (nonatomic, assign) BOOL coloursCommands;
/** Should comments be colored? */
@property (nonatomic, assign) BOOL coloursComments;
/** Should instructions be colored? */
@property (nonatomic, assign) BOOL coloursInstructions;
/** Should keywords be colored? */
@property (nonatomic, assign) BOOL coloursKeywords;
/** Should numbers be colored? */
@property (nonatomic, assign) BOOL coloursNumbers;
/** Should strings be colored? */
@property (nonatomic, assign) BOOL coloursStrings;
/** Should variables be colored? */
@property (nonatomic, assign) BOOL coloursVariables;


@end


NS_ASSUME_NONNULL_END
