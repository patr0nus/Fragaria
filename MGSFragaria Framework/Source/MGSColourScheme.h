//
//  MGSColourScheme.h
//  Fragaria
//
//  Created by Jim Derry on 3/16/15.
//
/// @cond PRIVATE

#import <Foundation/Foundation.h>


extern NSString * const MGSColourSchemeErrorDomain;

typedef NS_ENUM(NSUInteger, MGSColourSchemeErrorCode) {
    MGSColourSchemeWrongFileFormat = 1
};

@class MGSFragariaView;


/**
 *  MGSColourScheme defines a colour scheme for MGSColourSchemeController.
 *  @discussion Property names (except for displayName) are identical
 *      to the MGSFragariaView property names.
 */

@interface MGSColourScheme : NSObject <NSCopying, NSMutableCopying>


#pragma mark - Initializing a Colour Scheme
/// @name Initializing a Colour Scheme


/** Initialize a new colour scheme instance from a dictionary.
 *  @param dictionary The dictionary representation of the plist file that
 *      defines the color scheme. Each key must map to an NSColor value
 *      (no unarchiving will be attempted). */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

/** Initialize a new colour scheme with the currently selected color options
 *  on the specified instance of MGSFragariaView.
 *  @param fragaria The MGSFragariaView instance from which to copy the
 *         initial settings. */
- (instancetype)initWithFragaria:(MGSFragariaView *)fragaria displayName:(NSString *)name;

/** Initializes a new colour scheme instance from a file.
 *  @param file The URL of the plist file which contains the colour scheme values.
 *  @param err Upon return, if the initialization failed, contains an NSError object
 *         that describes the problem. */
- (instancetype)initWithSchemeFileURL:(NSURL *)file error:(NSError **)err;

/** Initializes a new colour scheme instance by copying another colour scheme.
 *  @param scheme The original colour scheme to copy. */
- (instancetype)initWithColourScheme:(MGSColourScheme *)scheme;

/** Initializes a new colour scheme instance with default properties. */
- (instancetype)init;


#pragma mark - Saving Colour Schemes
/// @name Saving Loading Colour Schemes


/** Writes the object as a plist to the given file.
 *  @param file The complete path and file to write.
 *  @param err Upon return, if the operation failed, contains an NSError object
 *         that describes the problem. */
- (BOOL)writeToSchemeFileURL:(NSURL *)file error:(NSError **)err;


/** An NSDictionary representation of the Colour Scheme Properties */
@property (nonatomic, assign, readonly) NSDictionary *dictionaryRepresentation;

/** An valid property list NSDictionary representation of the Colour Scheme
 *  properties.
 *  @discussion These are NSData objects already archived for disk. */
@property (nonatomic, assign, readonly) NSDictionary *propertyListRepresentation;


#pragma mark - Getting Information on Properties
/// @name Getting Information of Properties


/** An array of all of the properties of this class that constitute a scheme.
 *  Intended for use with KVO. Note that the names of the properties in this
 *  class and in MGSFragariaView are intentionally the same. */
+ (NSArray *)propertiesOfScheme;

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
/** Syntax color for attributes. */
@property (nonatomic, strong, readonly) NSColor *colourForAttributes;
/** Syntax color for autocomplete. */
@property (nonatomic, strong, readonly) NSColor *colourForAutocomplete;
/** Syntax color for commands. */
@property (nonatomic, strong, readonly) NSColor *colourForCommands;
/** Syntax color for comments. */
@property (nonatomic, strong, readonly) NSColor *colourForComments;
/** Syntax color for instructions. */
@property (nonatomic, strong, readonly) NSColor *colourForInstructions;
/** Syntax color for keywords. */
@property (nonatomic, strong, readonly) NSColor *colourForKeywords;
/** Syntax color for numbers. */
@property (nonatomic, strong, readonly) NSColor *colourForNumbers;
/** Syntax color for strings. */
@property (nonatomic, strong, readonly) NSColor *colourForStrings;
/** Syntax color for variables. */
@property (nonatomic, strong, readonly) NSColor *colourForVariables;

/** Should attributes be colored? */
@property (nonatomic, assign, readonly) BOOL coloursAttributes;
/** Should autocomplete be colored? */
@property (nonatomic, assign, readonly) BOOL coloursAutocomplete;
/** Should commands be colored? */
@property (nonatomic, assign, readonly) BOOL coloursCommands;
/** Should comments be colored? */
@property (nonatomic, assign, readonly) BOOL coloursComments;
/** Should instructions be colored? */
@property (nonatomic, assign, readonly) BOOL coloursInstructions;
/** Should keywords be colored? */
@property (nonatomic, assign, readonly) BOOL coloursKeywords;
/** Should numbers be colored? */
@property (nonatomic, assign, readonly) BOOL coloursNumbers;
/** Should strings be colored? */
@property (nonatomic, assign, readonly) BOOL coloursStrings;
/** Should variables be colored? */
@property (nonatomic, assign, readonly) BOOL coloursVariables;


#pragma mark - Checking Equality
/// @name Checking Equality


/** Indicates if two schemes have the same colour settings.
 *  @param scheme The scheme that you want to compare to the receiver. */
- (BOOL)isEqualToScheme:(MGSColourScheme *)scheme;


@end
