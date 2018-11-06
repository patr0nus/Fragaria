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
#import "MGSSyntaxDefinition.h"
#import "SMLLayoutManager.h"
#import "MGSSyntaxController.h"
#import "SMLTextView.h"
#import "NSScanner+Fragaria.h"
#import "MGSColourScheme.h"
#import "MGSSyntaxParser.h"


// syntax colouring information dictionary keys
NSString *SMLSyntaxGroup = @"group";
NSString *SMLSyntaxGroupID = @"groupID";
NSString *SMLSyntaxWillColour = @"willColour";
NSString *SMLSyntaxAttributes = @"attributes";
NSString *SMLSyntaxInfo = @"syntaxInfo";

// syntax colouring group names
NSString *SMLSyntaxGroupNumber = @"number";
NSString *SMLSyntaxGroupCommand = @"command";
NSString *SMLSyntaxGroupInstruction = @"instruction";
NSString *SMLSyntaxGroupKeyword = @"keyword";
NSString *SMLSyntaxGroupAutoComplete = @"autocomplete";
NSString *SMLSyntaxGroupVariable = @"variable";
NSString *SMLSyntaxGroupString = @"strings";
NSString *SMLSyntaxGroupAttribute = @"attribute";
NSString *SMLSyntaxGroupComment = @"comments";


@interface SMLSyntaxColouring()

@property (nonatomic, assign) BOOL coloursChanged;

@property (nonatomic, strong /*, nonnull */) MGSSyntaxParser *parser;

@end


@implementation SMLSyntaxColouring {
    SMLLayoutManager __weak *layoutManager;
    NSDictionary<NSString *, NSDictionary *> *attributeCache;
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
        NSDictionary *syndict = [[MGSSyntaxController sharedInstance] syntaxDictionaryWithName:sdname];
        MGSSyntaxDefinition *syndef = [[MGSSyntaxDefinition alloc] initFromSyntaxDictionary:syndict name:sdname];
        _parser = [[MGSSyntaxParser alloc] initWithSyntaxDefinition:syndef];

        // configure colouring
        self.coloursOnlyUntilEndOfLine = YES;
        _colourScheme = [[MGSColourScheme alloc] init];
        [self rebuildAttributesCache];

        [self layoutManagerDidChangeTextStorage];
	}
    
    return self;
}


#pragma mark - Colour Scheme Updating


- (void)setColourScheme:(MGSColourScheme *)colourScheme
{
    _colourScheme = colourScheme;
    [self rebuildAttributesCache];
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


- (void)setSyntaxDefinition:(MGSSyntaxDefinition *)syntaxDefinition
{
    BOOL colorsMultiline = self.coloursMultiLineStrings;
    BOOL colorsOnlyTillEnd = self.coloursOnlyUntilEndOfLine;
    _parser = [[MGSSyntaxParser alloc] initWithSyntaxDefinition:syntaxDefinition];
    _parser.coloursMultiLineStrings = colorsMultiline;
    _parser.coloursOnlyUntilEndOfLine = colorsOnlyTillEnd;
    [self invalidateAllColouring];
}


- (MGSSyntaxDefinition *)syntaxDefinition
{
    return _parser.syntaxDefinition;
}


- (void)setSyntaxDefinitionName:(NSString *)syntaxDefinitionName
{
	NSDictionary *syntaxDict;
	MGSSyntaxDefinition *syntaxDef;
	
	syntaxDict = [[MGSSyntaxController sharedInstance] syntaxDictionaryWithName:syntaxDefinitionName];
    syntaxDef = [[MGSSyntaxDefinition alloc] initFromSyntaxDictionary:syntaxDict name:syntaxDefinitionName];
	[self setSyntaxDefinition:syntaxDef];
}


- (NSString*)syntaxDefinitionName
{
    return self.syntaxDefinition.name;
}


/*
 *  @property colourMultiLineStrings
 */
- (void)setColoursMultiLineStrings:(BOOL)coloursMultiLineStrings
{
    _parser.coloursMultiLineStrings = coloursMultiLineStrings;
    [self invalidateAllColouring];
}

- (BOOL)coloursMultiLineStrings
{
    return _parser.coloursMultiLineStrings;
}


/*
 *  @property coloursOnlyUntilEndOfLine
 */
- (void)setColoursOnlyUntilEndOfLine:(BOOL)coloursOnlyUntilEndOfLine
{
    _parser.coloursOnlyUntilEndOfLine = coloursOnlyUntilEndOfLine;
    [self invalidateAllColouring];
}

- (BOOL)coloursOnlyUntilEndOfLine
{
    return _parser.coloursOnlyUntilEndOfLine;
}


/*
 * - isSyntaxColouringRequired
 */
- (BOOL)isSyntaxColouringRequired
{
    return self.syntaxDefinition && self.syntaxDefinition.syntaxDefinitionAllowsColouring;
}


- (NSTextStorage *)textStorage
{
    return layoutManager.textStorage;
}


#pragma mark - Colouring


/*
 * - rebuildAttributesCache
 */
- (void)rebuildAttributesCache
{
    attributeCache = @{
        SMLSyntaxGroupCommand:
            @{NSForegroundColorAttributeName: self.colourScheme.colourForCommands, SMLSyntaxGroup: SMLSyntaxGroupCommand},
        SMLSyntaxGroupComment:
            @{NSForegroundColorAttributeName: self.colourScheme.colourForComments, SMLSyntaxGroup: SMLSyntaxGroupComment},
        SMLSyntaxGroupInstruction:
            @{NSForegroundColorAttributeName: self.colourScheme.colourForInstructions, SMLSyntaxGroup: SMLSyntaxGroupInstruction},
        SMLSyntaxGroupKeyword:
            @{NSForegroundColorAttributeName: self.colourScheme.colourForKeywords, SMLSyntaxGroup: SMLSyntaxGroupKeyword},
        SMLSyntaxGroupAutoComplete:
            @{NSForegroundColorAttributeName: self.colourScheme.colourForAutocomplete, SMLSyntaxGroup: SMLSyntaxGroupAutoComplete},
        SMLSyntaxGroupString:
            @{NSForegroundColorAttributeName: self.colourScheme.colourForStrings, SMLSyntaxGroup: SMLSyntaxGroupString},
        SMLSyntaxGroupVariable:
            @{NSForegroundColorAttributeName: self.colourScheme.colourForVariables, SMLSyntaxGroup: SMLSyntaxGroupVariable},
        SMLSyntaxGroupAttribute:
            @{NSForegroundColorAttributeName: self.colourScheme.colourForAttributes, SMLSyntaxGroup: SMLSyntaxGroupAttribute},
        SMLSyntaxGroupNumber:
            @{NSForegroundColorAttributeName: self.colourScheme.colourForNumbers,
                      SMLSyntaxGroup: SMLSyntaxGroupNumber}
    };
    
    [self invalidateAllColouring];
}


/*
 * - invalidateAllColouring
 */
- (void)invalidateAllColouring
{
    NSString *string;
    
    string = self.layoutManager.textStorage.string;
	NSRange wholeRange = NSMakeRange(0, [string length]);
    
	[self resetColourInRange:wholeRange];
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
    
	if (!self.isSyntaxColouringRequired) return;
 
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
    NSString *string = self.layoutManager.textStorage.string;
    return [self.parser parseString:string inRange:rangeToRecolour forParserClient:self];
}


#pragma mark - Coloring primitives


- (void)resetColourInRange:(NSRange)range
{
    [self.textStorage addAttribute:NSForegroundColorAttributeName value:self.colourScheme.textColor range:range];
    [self.textStorage removeAttribute:SMLSyntaxGroup range:range];
}


- (void)setGroup:(nonnull NSString *)group forTokenInRange:(NSRange)range
{
    NSRange effectiveRange = NSMakeRange(0,0);
    NSRange bounds = NSMakeRange(0, [[layoutManager textStorage] length]);
    NSUInteger i = range.location;
    NSString *attr;
    NSSet *overlapSet = [NSSet setWithObjects:SMLSyntaxGroupCommand,
                         SMLSyntaxGroupInstruction, nil];
    
    while (NSLocationInRange(i, range)) {
        attr = [self.textStorage attribute:SMLSyntaxGroup atIndex:i
          longestEffectiveRange:&effectiveRange inRange:bounds];
        if (![overlapSet containsObject:attr]) {
            [self resetColourInRange:effectiveRange];
        }
        i = NSMaxRange(effectiveRange);
    }
    
    NSDictionary *colourDictionary = [attributeCache objectForKey:group];
	[self.textStorage addAttributes:colourDictionary range:range];
}


/*
 * - syntaxColouringGroupOfCharacterAtIndex:
 */
- (NSString*)syntaxColouringGroupOfCharacterAtIndex:(NSUInteger)index
{
    return [self.textStorage attribute:SMLSyntaxGroup atIndex:index effectiveRange:NULL];
}


- (BOOL)existsTokenAtIndex:(NSUInteger)index range:(NSRangePointer)res
{
    NSRange wholeRange = NSMakeRange(0, self.textStorage.length);
    return !![self.textStorage attribute:SMLSyntaxGroup atIndex:index longestEffectiveRange:res inRange:wholeRange];
}



@end
