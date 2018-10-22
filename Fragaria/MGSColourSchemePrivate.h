//
//  MGSColourSchemePrivate.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 20/09/18.
//

#import <Foundation/Foundation.h>
#import "MGSColourScheme.h"


@interface MGSColourScheme ()

- (BOOL)loadFromSchemeFileURL:(NSURL *)file error:(NSError **)err;

@property (nonatomic, strong) NSString *displayName;

@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSColor *defaultSyntaxErrorHighlightingColour;
@property (nonatomic, strong) NSColor *textInvisibleCharactersColour;
@property (nonatomic, strong) NSColor *currentLineHighlightColour;
@property (nonatomic, strong) NSColor *insertionPointColor;
@property (nonatomic, strong) NSColor *colourForAttributes;
@property (nonatomic, strong) NSColor *colourForAutocomplete;
@property (nonatomic, strong) NSColor *colourForCommands;
@property (nonatomic, strong) NSColor *colourForComments;
@property (nonatomic, strong) NSColor *colourForInstructions;
@property (nonatomic, strong) NSColor *colourForKeywords;
@property (nonatomic, strong) NSColor *colourForNumbers;
@property (nonatomic, strong) NSColor *colourForStrings;
@property (nonatomic, strong) NSColor *colourForVariables;

@property (nonatomic, assign) BOOL coloursAttributes;
@property (nonatomic, assign) BOOL coloursAutocomplete;
@property (nonatomic, assign) BOOL coloursCommands;
@property (nonatomic, assign) BOOL coloursComments;
@property (nonatomic, assign) BOOL coloursInstructions;
@property (nonatomic, assign) BOOL coloursKeywords;
@property (nonatomic, assign) BOOL coloursNumbers;
@property (nonatomic, assign) BOOL coloursStrings;
@property (nonatomic, assign) BOOL coloursVariables;

+ (NSSet *) propertiesAll;
+ (NSSet *) propertiesOfTypeBool;
+ (NSSet *) propertiesOfTypeColor;
+ (NSSet *) propertiesOfTypeString;

@end

