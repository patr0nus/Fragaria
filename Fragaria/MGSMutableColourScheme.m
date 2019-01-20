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
    static NSDictionary<SMLSyntaxGroup, NSString *> *groupMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        groupMap = @{
            SMLSyntaxGroupNumber: NSStringFromSelector(@selector(colourForNumbers)),
            SMLSyntaxGroupString: NSStringFromSelector(@selector(colourForStrings)),
            SMLSyntaxGroupCommand: NSStringFromSelector(@selector(colourForCommands)),
            SMLSyntaxGroupComment: NSStringFromSelector(@selector(colourForComments)),
            SMLSyntaxGroupKeyword: NSStringFromSelector(@selector(colourForKeywords)),
            SMLSyntaxGroupVariable: NSStringFromSelector(@selector(colourForVariables)),
            SMLSyntaxGroupAttribute: NSStringFromSelector(@selector(colourForAttributes)),
            SMLSyntaxGroupInstruction: NSStringFromSelector(@selector(colourForInstructions)),
            SMLSyntaxGroupAutoComplete: NSStringFromSelector(@selector(colourForAutocomplete))
        };
    });
    NSString *key = [groupMap objectForKey:group];
    if (!key)
        return;
    [self setValue:color forKey:key];
}


- (void)setColours:(BOOL)enabled syntaxGroup:(SMLSyntaxGroup)group
{
    static NSDictionary<SMLSyntaxGroup, NSString *> *groupMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        groupMap = @{
            SMLSyntaxGroupNumber: NSStringFromSelector(@selector(setColoursNumbers:)),
            SMLSyntaxGroupString: NSStringFromSelector(@selector(setColoursStrings:)),
            SMLSyntaxGroupCommand: NSStringFromSelector(@selector(setColoursCommands:)),
            SMLSyntaxGroupComment: NSStringFromSelector(@selector(setColoursComments:)),
            SMLSyntaxGroupKeyword: NSStringFromSelector(@selector(setColoursKeywords:)),
            SMLSyntaxGroupVariable: NSStringFromSelector(@selector(setColoursVariables:)),
            SMLSyntaxGroupAttribute: NSStringFromSelector(@selector(setColoursAttributes:)),
            SMLSyntaxGroupInstruction: NSStringFromSelector(@selector(setColoursInstructions:)),
            SMLSyntaxGroupAutoComplete: NSStringFromSelector(@selector(setColoursAutocomplete:))
        };
    });
    NSString *key = [groupMap objectForKey:group];
    if (!key)
        return;
    SEL selector = NSSelectorFromString(key);
    return ((void (*)(id _Nonnull, SEL _Nonnull, BOOL))objc_msgSend)(self, selector, enabled);
}


@end
