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

- (void)setColour:(NSColor *)color forSyntaxGroup:(SMLSyntaxGroup)group;
- (void)setFontVariant:(MGSFontVariant)variant forSyntaxGroup:(SMLSyntaxGroup)syntaxGroup;
- (void)setColours:(BOOL)enabled syntaxGroup:(SMLSyntaxGroup)group;


@end


NS_ASSUME_NONNULL_END
