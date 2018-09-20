//
//  MGSMutableColourScheme.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 20/09/18.
//

#import "MGSMutableColourScheme.h"
#import "MGSColourSchemePrivate.h"


@implementation MGSMutableColourScheme


@dynamic displayName;
@dynamic textColor;
@dynamic backgroundColor;
@dynamic defaultSyntaxErrorHighlightingColour;
@dynamic textInvisibleCharactersColour;
@dynamic currentLineHighlightColour;
@dynamic insertionPointColor;
@dynamic colourForAttributes;
@dynamic colourForAutocomplete;
@dynamic colourForCommands;
@dynamic colourForComments;
@dynamic colourForInstructions;
@dynamic colourForKeywords;
@dynamic colourForNumbers;
@dynamic colourForStrings;
@dynamic colourForVariables;

@dynamic coloursAttributes;
@dynamic coloursAutocomplete;
@dynamic coloursCommands;
@dynamic coloursComments;
@dynamic coloursInstructions;
@dynamic coloursKeywords;
@dynamic coloursNumbers;
@dynamic coloursStrings;
@dynamic coloursVariables;


- (id)copyWithZone:(NSZone *)zone
{
    return [[MGSMutableColourScheme alloc] initWithColourScheme:self];
}


- (BOOL)loadFromSchemeFileURL:(NSURL *)file error:(NSError * _Nullable __autoreleasing *)err
{
    return [super loadFromSchemeFileURL:file error:err];
}


@end
