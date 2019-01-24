//
//  MGSColourSchemePrivate.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 20/09/18.
//

#import <Foundation/Foundation.h>
#import "MGSColourScheme.h"

NS_ASSUME_NONNULL_BEGIN


extern NSString * const MGSColourSchemeKeySyntaxGroupOptions;

typedef NSString * const MGSColourSchemeGroupOptionKey NS_EXTENSIBLE_STRING_ENUM;
extern MGSColourSchemeGroupOptionKey MGSColourSchemeGroupOptionKeyEnabled;
extern MGSColourSchemeGroupOptionKey MGSColourSchemeGroupOptionKeyColour;


@interface MGSColourScheme ()

- (BOOL)loadFromSchemeFileURL:(NSURL *)file error:(NSError **)err;

@property (nonatomic, strong) NSString *displayName;

@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSColor *defaultSyntaxErrorHighlightingColour;
@property (nonatomic, strong) NSColor *textInvisibleCharactersColour;
@property (nonatomic, strong) NSColor *currentLineHighlightColour;
@property (nonatomic, strong) NSColor *insertionPointColor;

@property (nonatomic, copy) NSDictionary<SMLSyntaxGroup, NSDictionary<MGSColourSchemeGroupOptionKey, id> *> *syntaxGroupOptions;

- (void)setColour:(NSColor *)color forSyntaxGroup:(SMLSyntaxGroup)group;
- (void)setColours:(BOOL)enabled syntaxGroup:(SMLSyntaxGroup)group;

@end


@interface MGSColourSchemeGroupData : NSObject

- (instancetype)initWithOptionDictionary:(NSDictionary<MGSColourSchemeGroupOptionKey, id> *)optionDictionary;
- (NSDictionary<MGSColourSchemeGroupOptionKey, id> *)optionDictionary;

@property (nonatomic) BOOL enabled;
@property (nonatomic, nullable) NSColor *color;

@end


NS_ASSUME_NONNULL_END

