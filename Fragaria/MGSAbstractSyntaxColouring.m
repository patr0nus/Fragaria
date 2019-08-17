//
//  MGSAbstractSyntaxColouring.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 07/07/2019.
//

#import "MGSAbstractSyntaxColouring.h"
#import "MGSSyntaxController.h"
#import "NSScanner+Fragaria.h"
#import "MGSColourScheme.h"
#import "MGSSyntaxParser.h"


// syntax colouring information dictionary keys
NSAttributedStringKey MGSSyntaxGroupAttributeName = @"group";

// syntax colouring group names
NSString * const MGSSyntaxGroupNumber       = @"number";
NSString * const MGSSyntaxGroupCommand      = @"command";
NSString * const MGSSyntaxGroupInstruction  = @"instruction";
NSString * const MGSSyntaxGroupKeyword      = @"keyword";
NSString * const MGSSyntaxGroupAutoComplete = @"autocomplete";
NSString * const MGSSyntaxGroupVariable     = @"variable";
NSString * const MGSSyntaxGroupString       = @"strings";
NSString * const MGSSyntaxGroupAttribute    = @"attribute";
NSString * const MGSSyntaxGroupComment      = @"comments";


@interface MGSAbstractSyntaxColouring ()

@property (nonatomic) NSString *stringToParse;

@property (nonatomic) NSRange rangeToParse;

@end


@implementation MGSAbstractSyntaxColouring


- (instancetype)init
{
    if ((self = [super init])) {
        _inspectedCharacterIndexes = [[NSMutableIndexSet alloc] init];
    
        NSString *sdname = [MGSSyntaxController standardSyntaxDefinitionName];
        _parser = [[MGSSyntaxController sharedInstance] parserForSyntaxDefinitionName:sdname];

        // configure colouring
        _colourScheme = [[MGSColourScheme alloc] init];
        _textFont = [NSFont userFontOfSize:0];
        self.parser.coloursOnlyUntilEndOfLine = YES;
        [self invalidateAllColouring];
    }
    
    return self;
}


- (NSMutableAttributedString *)textStorage
{
    [NSException raise:NSGenericException format:@"abstract method"];
    return nil;
}


#pragma mark - Coloring Settings


- (void)setParser:(MGSSyntaxParser *)parser
{
    [self invalidateAllColouring];
    _parser = parser;
}


- (void)setColourScheme:(MGSColourScheme *)colourScheme
{
    _colourScheme = colourScheme;
    [self invalidateAllColouring];
}


- (void)setTextFont:(NSFont *)textFont
{
    _textFont = textFont;
    [self invalidateAllColouring];
}


- (void)setColoursMultiLineStrings:(BOOL)coloursMultiLineStrings
{
    self.parser.coloursMultiLineStrings = coloursMultiLineStrings;
    [self invalidateAllColouring];
}


- (BOOL)coloursMultiLineStrings
{
    return self.parser.coloursMultiLineStrings;
}


- (void)setColoursOnlyUntilEndOfLine:(BOOL)coloursOnlyUntilEndOfLine
{
    self.parser.coloursOnlyUntilEndOfLine = coloursOnlyUntilEndOfLine;
    [self invalidateAllColouring];
}


- (BOOL)coloursOnlyUntilEndOfLine
{
    return self.parser.coloursOnlyUntilEndOfLine;
}


#pragma mark - Colouring


- (void)invalidateAllColouring
{
    NSString *string;
    
    string = self.textStorage.string;
    NSRange wholeRange = NSMakeRange(0, [string length]);
    
    [self resetTokenGroupsInRange:wholeRange];
    [self.inspectedCharacterIndexes removeAllIndexes];
}


- (void)recolourRange:(NSRange)range
{
    NSMutableIndexSet *invalidRanges;
 
    [self.textStorage beginEditing];

    invalidRanges = [NSMutableIndexSet indexSetWithIndexesInRange:range];
    [invalidRanges removeIndexes:self.inspectedCharacterIndexes];
    [invalidRanges enumerateRangesUsingBlock:^(NSRange range, BOOL *stop){
        if (![self.inspectedCharacterIndexes containsIndexesInRange:range]) {
            NSRange nowValid = [self recolourChangedRange:range];
            [self.inspectedCharacterIndexes addIndexesInRange:nowValid];
        }
    }];
    
    [self.textStorage endEditing];
}


- (NSRange)recolourChangedRange:(NSRange)rangeToRecolour
{
    self.stringToParse = self.textStorage.string;
    self.rangeToParse = rangeToRecolour;
    return [self.parser parseForClient:self];
}


#pragma mark - Coloring primitives


- (NSRange)rangeOfAtomicTokenAtCharacterIndex:(NSUInteger)i
{
    NSRange bounds = NSMakeRange(0, [self.textStorage length]);
    if (i >= NSMaxRange(bounds))
        return NSMakeRange(i, 0);
    
    NSRange effectiveRange = NSMakeRange(0,0);
    NSString *attr = [self.textStorage attribute:MGSSyntaxGroupAttributeName atIndex:i longestEffectiveRange:&effectiveRange inRange:bounds];
    
    if (attr && [attr hasPrefix:@"A_"])
        return effectiveRange;
    return NSMakeRange(i, 0);
}


- (NSRange)resetTokenGroupsInRange:(NSRange)range
{
    NSRange lexpand = [self rangeOfAtomicTokenAtCharacterIndex:range.location];
    NSRange rexpand;
    if (range.length > 0)
        rexpand = [self rangeOfAtomicTokenAtCharacterIndex:range.location + range.length - 1];
    else
        rexpand = range;
    NSRange realrange = NSUnionRange(lexpand, NSUnionRange(range, rexpand));
    
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: self.colourScheme.textColor,
        NSFontAttributeName: self.textFont,
        NSUnderlineStyleAttributeName: @(0)};
    [self.textStorage addAttributes:attributes range:realrange];
    [self.textStorage removeAttribute:MGSSyntaxGroupAttributeName range:realrange];
    
    return realrange;
}


- (void)setGroup:(nonnull NSString *)group forTokenInRange:(NSRange)range atomic:(BOOL)atomic
{
    NSRange effectiveRange = NSMakeRange(0,0);
    NSRange bounds = NSMakeRange(0, [self.textStorage length]);
    NSUInteger i = range.location;
    NSString *attr;
    
    while (NSLocationInRange(i, range)) {
        attr = [self.textStorage attribute:MGSSyntaxGroupAttributeName atIndex:i
          longestEffectiveRange:&effectiveRange inRange:bounds];
        if (attr && [attr hasPrefix:@"A_"]) {
            [self resetTokenGroupsInRange:effectiveRange];
        }
        i = NSMaxRange(effectiveRange);
    }
    
    NSDictionary *colourDictionary = [self.colourScheme attributesForSyntaxGroup:group textFont:self.textFont];
    [self.textStorage addAttributes:colourDictionary range:range];
 
    NSString *realgroup;
    if (atomic) {
        realgroup = [@"A_" stringByAppendingString:group];
    } else {
        realgroup = [@"a_" stringByAppendingString:group];
    }
    [self.textStorage addAttribute:MGSSyntaxGroupAttributeName value:realgroup range:range];
}


- (BOOL)existsTokenAtIndex:(NSUInteger)index
{
    return !![self.textStorage attribute:MGSSyntaxGroupAttributeName atIndex:index effectiveRange:NULL];
}


- (nullable MGSSyntaxGroup)groupOfTokenAtCharacterIndex:(NSUInteger)index
{
    return [self groupOfTokenAtCharacterIndex:index isAtomic:NULL range:NULL];
}


- (nullable MGSSyntaxGroup)groupOfTokenAtCharacterIndex:(NSUInteger)index isAtomic:(nullable BOOL *)atomic range:(nullable NSRangePointer)range
{
    NSString *raw;
    if (!range) {
        raw = [self.textStorage attribute:MGSSyntaxGroupAttributeName atIndex:index effectiveRange:NULL];
    } else {
        NSRange wholeRange = NSMakeRange(0, self.textStorage.length);
        raw = [self.textStorage attribute:MGSSyntaxGroupAttributeName atIndex:index longestEffectiveRange:range inRange:wholeRange];
    }
    if (!raw)
        return nil;
    if (atomic) {
        *atomic = [raw hasPrefix:@"A_"];
    }
    return [raw substringFromIndex:2];
}


@end
