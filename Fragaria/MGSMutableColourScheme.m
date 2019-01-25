//
//  MGSMutableColourScheme.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 20/09/18.
//

#import <objc/message.h>
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


- (id)copyWithZone:(NSZone *)zone
{
    return [[MGSMutableColourScheme alloc] initWithColourScheme:self];
}


- (BOOL)loadFromSchemeFileURL:(NSURL *)file error:(NSError * _Nullable __autoreleasing *)err
{
    return [super loadFromSchemeFileURL:file error:err];
}


- (void)setColour:(NSColor *)color forSyntaxGroup:(SMLSyntaxGroup)group
{
    [super setColour:color forSyntaxGroup:group];
}


- (void)setColours:(BOOL)enabled syntaxGroup:(SMLSyntaxGroup)group
{
    [super setColours:enabled syntaxGroup:group];
}


- (void)setFontVariant:(MGSFontVariant)variant forSyntaxGroup:(SMLSyntaxGroup)syntaxGroup
{
    [super setFontVariant:variant forSyntaxGroup:syntaxGroup];
}


@end
