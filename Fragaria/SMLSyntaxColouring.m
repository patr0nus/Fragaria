/*

 MGSFragaria
 Written by Jonathan Mitchell, jonathan@mugginsoft.com
 Find the latest version at https://github.com/mugginsoft/Fragaria
 
 Smultron version 3.6b1, 2009-09-12
 Written by Peter Borg, pgw3@mac.com
 Find the latest version at http://smultron.sourceforge.net

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use
 this file except in compliance with the License. You may obtain a copy of the
 License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed
 under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 CONDITIONS OF ANY KIND, either express or implied. See the License for the
 specific language governing permissions and limitations under the License.
*/

#import "SMLSyntaxColouring.h"
#import "SMLLayoutManager.h"
#import "MGSSyntaxController.h"
#import "SMLTextView.h"
#import "NSScanner+Fragaria.h"
#import "MGSColourScheme.h"
#import "MGSSyntaxParser.h"


// syntax colouring information dictionary keys
NSAttributedStringKey SMLSyntaxGroupAttributeName = @"group";

// syntax colouring group names
NSString * const SMLSyntaxGroupNumber = @"number";
NSString * const SMLSyntaxGroupCommand = @"command";
NSString * const SMLSyntaxGroupInstruction = @"instruction";
NSString * const SMLSyntaxGroupKeyword = @"keyword";
NSString * const SMLSyntaxGroupAutoComplete = @"autocomplete";
NSString * const SMLSyntaxGroupVariable = @"variable";
NSString * const SMLSyntaxGroupString = @"strings";
NSString * const SMLSyntaxGroupAttribute = @"attribute";
NSString * const SMLSyntaxGroupComment = @"comments";


@interface SMLSyntaxColouring()

@property (nonatomic, assign) BOOL coloursChanged;

@property (nonatomic) NSString *stringToParse;

@property (nonatomic) NSRange rangeToParse;

@end


@implementation SMLSyntaxColouring
{
    SMLLayoutManager __weak *layoutManager;
}


@synthesize layoutManager;


#pragma mark - Instance methods


/*
 * - initWithLayoutManager:
 */
- (instancetype)initWithLayoutManager:(SMLLayoutManager *)lm
{
    if ((self = [super init])) {
        layoutManager = lm;
        
        _inspectedCharacterIndexes = [[NSMutableIndexSet alloc] init];
        
        NSString *sdname = [MGSSyntaxController standardSyntaxDefinitionName];
        _parser = [[MGSSyntaxController sharedInstance] parserForSyntaxDefinitionName:sdname];

        // configure colouring
        _colourScheme = [[MGSColourScheme alloc] init];
        _textFont = [NSFont userFontOfSize:0];
        self.parser.coloursOnlyUntilEndOfLine = YES;
        [self invalidateAllColouring];

        [self layoutManagerDidChangeTextStorage];
	}
    
    return self;
}


#pragma mark - Colour Scheme & Font Updating


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


#pragma mark - Text change notification


- (void)textStorageDidProcessEditing:(NSNotification*)notification
{
    NSTextStorage *ts = [notification object];
    
    if (!(ts.editedMask & NSTextStorageEditedCharacters))
        return;
    
    NSRange newRange = [ts editedRange];
    NSRange oldRange = newRange;
    NSInteger changeInLength = [ts changeInLength];
    NSMutableIndexSet *insp = self.inspectedCharacterIndexes;
    
    oldRange.length -= changeInLength;
    [insp shiftIndexesStartingAtIndex:NSMaxRange(oldRange) by:changeInLength];
    newRange = [[ts string] lineRangeForRange:newRange];
    [insp removeIndexesInRange:newRange];
}


#pragma mark - Property getters/setters


- (void)layoutManagerWillChangeTextStorage
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NSTextStorageDidProcessEditingNotification
                object:layoutManager.textStorage];
}


- (void)layoutManagerDidChangeTextStorage
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(textStorageDidProcessEditing:)
               name:NSTextStorageDidProcessEditingNotification object:layoutManager.textStorage];
}


/*
 *  @property colourMultiLineStrings
 */
- (void)setColoursMultiLineStrings:(BOOL)coloursMultiLineStrings
{
    self.parser.coloursMultiLineStrings = coloursMultiLineStrings;
    [self invalidateAllColouring];
}

- (BOOL)coloursMultiLineStrings
{
    return self.parser.coloursMultiLineStrings;
}


/*
 *  @property coloursOnlyUntilEndOfLine
 */
- (void)setColoursOnlyUntilEndOfLine:(BOOL)coloursOnlyUntilEndOfLine
{
    self.parser.coloursOnlyUntilEndOfLine = coloursOnlyUntilEndOfLine;
    [self invalidateAllColouring];
}

- (BOOL)coloursOnlyUntilEndOfLine
{
    return self.parser.coloursOnlyUntilEndOfLine;
}


- (NSTextStorage *)textStorage
{
    return layoutManager.textStorage;
}


- (void)setParser:(MGSSyntaxParser *)parser
{
    [self invalidateAllColouring];
    _parser = parser;
}


#pragma mark - Colouring


/*
 * - invalidateAllColouring
 */
- (void)invalidateAllColouring
{
    NSString *string;
    
    string = self.layoutManager.textStorage.string;
	NSRange wholeRange = NSMakeRange(0, [string length]);
    
	[self resetTokenGroupsInRange:wholeRange];
    [self.inspectedCharacterIndexes removeAllIndexes];
}


/*
 * - invalidateVisibleRange
 */
- (void)invalidateVisibleRangeOfTextView:(SMLTextView *)textView
{
    NSMutableIndexSet *validRanges;

    validRanges = self.inspectedCharacterIndexes;
    NSRect visibleRect = [[[textView enclosingScrollView] contentView] documentVisibleRect];
    NSRange visibleRange = [[textView layoutManager] glyphRangeForBoundingRect:visibleRect inTextContainer:[textView textContainer]];
    [validRanges removeIndexesInRange:visibleRange];
}


/*
 * - recolourRange:
 */
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
    self.stringToParse = self.layoutManager.textStorage.string;
    self.rangeToParse = rangeToRecolour;
    return [self.parser parseForClient:self];
}


#pragma mark - Coloring primitives


- (NSRange)rangeOfAtomicTokenAtCharacterIndex:(NSUInteger)i
{
    NSRange bounds = NSMakeRange(0, [[layoutManager textStorage] length]);
    if (i >= NSMaxRange(bounds))
        return NSMakeRange(i, 0);
    
    NSRange effectiveRange = NSMakeRange(0,0);
    NSString *attr = [self.textStorage attribute:SMLSyntaxGroupAttributeName atIndex:i longestEffectiveRange:&effectiveRange inRange:bounds];
    
    if (attr && [attr hasPrefix:@"A_"])
        return effectiveRange;
    return NSMakeRange(i, 0);
}


- (NSRange)resetTokenGroupsInRange:(NSRange)range
{
    NSRange lexpand = [self rangeOfAtomicTokenAtCharacterIndex:range.location];
    NSRange rexpand = [self rangeOfAtomicTokenAtCharacterIndex:range.location + range.length];
    NSRange realrange = NSUnionRange(lexpand, NSUnionRange(range, rexpand));
    
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: self.colourScheme.textColor,
        NSFontAttributeName: self.textFont};
    [self.textStorage addAttributes:attributes range:realrange];
    [self.textStorage removeAttribute:SMLSyntaxGroupAttributeName range:realrange];
    
    return realrange;
}


- (void)setGroup:(nonnull NSString *)group forTokenInRange:(NSRange)range atomic:(BOOL)atomic
{
    NSRange effectiveRange = NSMakeRange(0,0);
    NSRange bounds = NSMakeRange(0, [[layoutManager textStorage] length]);
    NSUInteger i = range.location;
    NSString *attr;
    
    while (NSLocationInRange(i, range)) {
        attr = [self.textStorage attribute:SMLSyntaxGroupAttributeName atIndex:i
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
    [self.textStorage addAttribute:SMLSyntaxGroupAttributeName value:realgroup range:range];
}


- (BOOL)existsTokenAtIndex:(NSUInteger)index
{
    return !![self.textStorage attribute:SMLSyntaxGroupAttributeName atIndex:index effectiveRange:NULL];
}


- (nullable SMLSyntaxGroup)groupOfTokenAtCharacterIndex:(NSUInteger)index
{
    return [self groupOfTokenAtCharacterIndex:index isAtomic:NULL range:NULL];
}


- (nullable SMLSyntaxGroup)groupOfTokenAtCharacterIndex:(NSUInteger)index isAtomic:(nullable BOOL *)atomic range:(nullable NSRangePointer)range
{
    NSString *raw;
    if (!range) {
        raw = [self.textStorage attribute:SMLSyntaxGroupAttributeName atIndex:index effectiveRange:NULL];
    } else {
        NSRange wholeRange = NSMakeRange(0, self.textStorage.length);
        raw = [self.textStorage attribute:SMLSyntaxGroupAttributeName atIndex:index longestEffectiveRange:range inRange:wholeRange];
    }
    if (!raw)
        return nil;
    if (atomic) {
        *atomic = [raw hasPrefix:@"A_"];
    }
    return [raw substringFromIndex:2];
}


@end
