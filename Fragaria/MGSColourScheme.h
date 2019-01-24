//
//  MGSColourScheme.h
//  Fragaria
//
//  Created by Jim Derry on 3/16/15.
//

#import <Cocoa/Cocoa.h>
#import "MGSSyntaxParserClient.h"

NS_ASSUME_NONNULL_BEGIN


extern NSString * const MGSColourSchemeErrorDomain;

typedef NS_ENUM(NSUInteger, MGSColourSchemeErrorCode) {
    MGSColourSchemeWrongFileFormat = 1
};

@class MGSFragariaView;


/**
 *  MGSColourScheme defines a colour scheme for MGSColourSchemeListController.
 *  @discussion Property names (except for displayName) are identical
 *      to the MGSFragariaView property names.
 */

@interface MGSColourScheme : NSObject <NSCopying, NSMutableCopying>


#pragma mark - Initializing a Colour Scheme
/// @name Initializing a Colour Scheme


/** Initialize a new colour scheme instance from a dictionary.
 *  @param dictionary A dictionary in the same format as what is
 *    returned by -dictionaryRepresentation. */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

/** Initializes a new colour scheme instance from a file.
 *  @param file The URL of the plist file.
 *  @param err Upon return, if the initialization failed, contains an NSError object
 *         that describes the problem. */
- (instancetype)initWithSchemeFileURL:(NSURL *)file error:(out NSError **)err;

/** Initializes a new colour scheme instance from a deserialized property list.
 *  @param plist The deserialized plist
 *  @param err   Upon return, if the initialization failed, contains an NSError object
 *               which describes the problem. */
- (instancetype)initWithPropertyList:(id)plist error:(out NSError **)err;

/** Initializes a new colour scheme instance by copying another colour scheme.
 *  @param scheme The original colour scheme to copy. */
- (instancetype)initWithColourScheme:(MGSColourScheme *)scheme;

/** Initializes a new colour scheme instance with the default properties for the current
 * appearance. */
- (instancetype)init;

/** Returns a colour scheme instance with the default properties for
 * the specified appearance (or the current appearance if appearance is nil)
 * @param appearance The appearance appropriate for the returned scheme */
+ (instancetype)defaultColorSchemeForAppearance:(NSAppearance *)appearance;


#pragma mark - Saving Colour Schemes
/// @name Saving Loading Colour Schemes


/** Writes the object as a plist to the given file.
 *  @param file The complete path and file to write.
 *  @param err Upon return, if the operation failed, contains an NSError object
 *         that describes the problem.
 *  @returns YES if the operation succeeded, otherwise NO. */
- (BOOL)writeToSchemeFileURL:(NSURL *)file error:(out NSError **)err;


/** An NSDictionary representation of the Colour Scheme.
 *  @warning The structure used by the returned dictionary is private. To access
 *     the contents of a dictionary representation of an MGSColourScheme, always
 *     initialize a new MGSColourScheme instead of accessing the contents of the
 *     dictionary directly. */
@property (nonatomic, assign, readonly) NSDictionary *dictionaryRepresentation;

/** A serializable NSDictionary representation of the Colour Scheme.
 *  @discussion Like for dictionaryRepresentation, the structure of the returned
 *     object is private as well. However, the dictionary returned by this property is
 *     forwards and backwards compatible with other versions of Fragaria when
 *     used to initialize a new MGSColourScheme via -initWithPropertyList:error:. */
@property (nonatomic, assign, readonly) id propertyListRepresentation;


#pragma mark - Getting Information on Properties
/// @name Getting Information of Properties


/** An array of colour schemes included with Fragaria.
 *  @discussion A new copy of the schemes is generated for every invocation
 *      of this method, as colour schemes are mutable. */
+ (NSArray <MGSColourScheme *> *)builtinColourSchemes;


#pragma mark - Colour Scheme Properties
/// @name Colour Scheme Properties


/** Display name of the color scheme. */
@property (nonatomic, strong, readonly) NSString *displayName;

/** Base text color. */
@property (nonatomic, strong, readonly) NSColor *textColor;
/** Editor background color. */
@property (nonatomic, strong, readonly) NSColor *backgroundColor;
/** Syntax error background highlighting color. */
@property (nonatomic, strong, readonly) NSColor *defaultSyntaxErrorHighlightingColour;
/** Editor invisible characters color. */
@property (nonatomic, strong, readonly) NSColor *textInvisibleCharactersColour;
/** Editor current line highlight color. */
@property (nonatomic, strong, readonly) NSColor *currentLineHighlightColour;
/** Editor insertion point color. */
@property (nonatomic, strong, readonly) NSColor *insertionPointColor;

/** Returns the highlighting colour of specified syntax group, or nil
 *  if the specified group is not associated with an highlighting colour.
 *  @param syntaxGroup The syntax group identifier. */
- (nullable NSColor *)colourForSyntaxGroup:(SMLSyntaxGroup)syntaxGroup;

/** Returns if the specified syntax group will be highlighted.
 *  @param syntaxGroup The syntax group identifier. */
- (BOOL)coloursSyntaxGroup:(SMLSyntaxGroup)syntaxGroup;

/** Returns the dictionary of attributes to use for colouring a
 *  token of a given syntax group.
 *  @param group The syntax group of the token.
 *  @param font The font used for non-highlighted text. */
- (NSDictionary<NSAttributedStringKey, id> *)attributesForSyntaxGroup:(SMLSyntaxGroup)group textFont:(NSFont *)font;


#pragma mark - Checking Equality
/// @name Checking Equality


/** Indicates if two schemes have the same colour settings.
 *  @param scheme The scheme that you want to compare to the receiver. */
- (BOOL)isEqualToScheme:(MGSColourScheme *)scheme;


@end

NS_ASSUME_NONNULL_END

