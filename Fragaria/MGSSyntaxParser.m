//
//  MGSSyntaxParser.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 30/10/2018.
//

#import "MGSSyntaxParser.h"
#import "MGSSyntaxDefinition.h"
#import "NSScanner+Fragaria.h"


// syntax colouring group IDs
enum {
    kSMLSyntaxGroupNumber = 0,
    kSMLSyntaxGroupCommand = 1,
    kSMLSyntaxGroupInstruction = 2,
    kSMLSyntaxGroupKeyword = 3,
    kSMLSyntaxGroupAutoComplete = 4,
    kSMLSyntaxGroupVariable = 5,
    kSMLSyntaxGroupSecondString = 6,
    kSMLSyntaxGroupFirstString = 7,
    kSMLSyntaxGroupAttribute = 8,
    kSMLSyntaxGroupSingleLineComment = 9,
    kSMLSyntaxGroupMultiLineComment = 10,
    kSMLSyntaxGroupSecondStringPass2 = 11,
    kSMLCountOfSyntaxGroups = 12
};
typedef NSInteger SMLSyntaxGroupInteger;


@interface MGSSyntaxParser ()

@property (nonatomic, weak) id<MGSSyntaxParserClient> client;

@end


@implementation MGSSyntaxParser
{
    NSString *firstStringPattern, *secondStringPattern;
    NSString *firstMultilineStringPattern, *secondMultilineStringPattern;
}


- (instancetype)initWithSyntaxDefinition:(MGSSyntaxDefinition *)sdef
{
    self = [super init];
    _syntaxDefinition = sdef;
    [self prepareRegularExpressions];
    return self;
}


- (void)prepareRegularExpressions
{
    NSString *firstString = self.syntaxDefinition.firstString;
    NSString *secondString = self.syntaxDefinition.secondString;
    
    firstStringPattern = [NSString stringWithFormat:@"\\W%@[^%@\\\\\\r\\n]*+(?:\\\\(?:.|$)[^%@\\\\\\r\\n]*+)*+%@", firstString, firstString, firstString, firstString];
    
    secondStringPattern = [NSString stringWithFormat:@"\\W%@[^%@\\\\\\r\\n]*+(?:\\\\(?:.|$)[^%@\\\\]*+)*+%@", secondString, secondString, secondString, secondString];
    
    firstMultilineStringPattern = [NSString stringWithFormat:@"\\W%@[^%@\\\\]*+(?:\\\\(?:.|$)[^%@\\\\]*+)*+%@", firstString, firstString, firstString, firstString];
    
    secondMultilineStringPattern = [NSString stringWithFormat:@"\\W%@[^%@\\\\]*+(?:\\\\(?:.|$)[^%@\\\\]*+)*+%@", secondString, secondString, secondString, secondString];
}


#pragma mark - Common colouring methods


- (void)recognizeKeywordsFromSet:(NSSet*)keywords ofGroup:(NSString *)group inRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSUInteger colourStartLocation, colourEndLocation;
    NSInteger rangeLocation = rangeToRecolour.location;
    NSString *documentString = [documentScanner string];
    NSString *rangeString = [rangeScanner string];
    NSUInteger rangeStringLength = [rangeString length];
    
    // scan range to end
    while (![rangeScanner isAtEnd]) {
        [rangeScanner scanUpToCharactersFromSet:self.syntaxDefinition.keywordStartCharacterSet intoString:nil];
        colourStartLocation = [rangeScanner scanLocation];
        if ((colourStartLocation + 1) < rangeStringLength) {
            [rangeScanner mgs_setScanLocation:(colourStartLocation + 1)];
        }
        [rangeScanner scanUpToCharactersFromSet:self.syntaxDefinition.keywordEndCharacterSet intoString:nil];
        
        colourEndLocation = [rangeScanner scanLocation];
        if (colourEndLocation > rangeStringLength || colourStartLocation == colourEndLocation) {
            break;
        }
        
        NSString *keywordTestString = nil;
        if (!self.syntaxDefinition.keywordsCaseSensitive) {
            keywordTestString = [[documentString substringWithRange:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)] lowercaseString];
        } else {
            keywordTestString = [documentString substringWithRange:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)];
        }
        if ([keywords containsObject:keywordTestString]) {
            if (!self.syntaxDefinition.recolourKeywordIfAlreadyColoured) {
                if ([[self.client syntaxColouringGroupOfCharacterAtIndex:colourStartLocation + rangeLocation] isEqual:SMLSyntaxGroupCommand]) {
                    continue;
                }
            }
            [self.client setGroup:group forTokenInRange:NSMakeRange(colourStartLocation + rangeLocation, [rangeScanner scanLocation] - colourStartLocation)];
        }
    }
}


- (void)recognizeMatchesOfPattern:(NSString*)pattern ofGroup:(NSString*)group inString:(NSString *)documentString range:(NSRange)colouringRange
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    if (!regex) return;
    
    [regex enumerateMatchesInString:documentString options:0 range:colouringRange usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        [self.client setGroup:group forTokenInRange:[match range]];
    }];
}


#pragma mark - Parser Entry Point


- (NSRange)parseString:(NSString *)documentString inRange:(NSRange)rangeToRecolour forParserClient:(id<MGSSyntaxParserClient>)client
{
    // setup
    self.client = client;
    NSRange effectiveRange = [documentString lineRangeForRange:rangeToRecolour];

    // trace
    //NSLog(@"rangeToRecolor location %i length %i", rangeToRecolour.location, rangeToRecolour.length);

    // adjust effective range
    //
    // When multiline strings are coloured we need to scan backwards to
    // find where the string might have started if it's "above" the top of the screen,
    // or we need to scan forwards to find where a multiline string which wraps off
    // the range ends.
    //
    // This is not always correct but it's better than nothing.
    //
    if (self.coloursMultiLineStrings) {
        NSInteger beginFirstStringInMultiLine = [documentString rangeOfString:self.syntaxDefinition.firstString options:NSBackwardsSearch range:NSMakeRange(0, effectiveRange.location)].location;
        if (beginFirstStringInMultiLine != NSNotFound) {
            if ([[client syntaxColouringGroupOfCharacterAtIndex:beginFirstStringInMultiLine] isEqual:@"strings"]) {
                NSInteger startOfLine = [documentString lineRangeForRange:NSMakeRange(beginFirstStringInMultiLine, 0)].location;
                effectiveRange = NSMakeRange(startOfLine, rangeToRecolour.length + (rangeToRecolour.location - startOfLine));
            }
        }
        
        
        NSInteger lastStringBegin = [documentString rangeOfString:self.syntaxDefinition.firstString options:NSBackwardsSearch range:rangeToRecolour].location;
        if (lastStringBegin != NSNotFound) {
            NSRange restOfString = NSMakeRange(NSMaxRange(rangeToRecolour), 0);
            restOfString.length = [documentString length] - restOfString.location;
            NSInteger lastStringEnd = [documentString rangeOfString:self.syntaxDefinition.firstString options:0 range:restOfString].location;
            if (lastStringEnd != NSNotFound) {
                NSInteger endOfLine = NSMaxRange([documentString lineRangeForRange:NSMakeRange(lastStringEnd, 0)]);
                effectiveRange = NSUnionRange(effectiveRange, NSMakeRange(lastStringBegin, endOfLine-lastStringBegin));
            }
        }
    }
    
    /* Expand the range to not start or end in the middle of an already coloured
     * block. */
    NSRange longRange;
    
    if ([client existsTokenAtIndex:effectiveRange.location range:&longRange]) {
        effectiveRange = NSUnionRange(effectiveRange, longRange);
    }
    if (NSMaxRange(effectiveRange) < documentString.length && [client existsTokenAtIndex:NSMaxRange(effectiveRange) range:&longRange]) {
        effectiveRange = NSUnionRange(effectiveRange, longRange);
    }
    
    // assign range string
    NSString *rangeString = [documentString substringWithRange:effectiveRange];
    NSUInteger rangeStringLength = [rangeString length];
    if (rangeStringLength == 0) {
        return effectiveRange;
    }
    
    // allocate the range scanner
    NSScanner *rangeScanner = [[NSScanner alloc] initWithString:rangeString];
    [rangeScanner setCharactersToBeSkipped:nil];
    
    // allocate the document scanner
    NSScanner *documentScanner = [[NSScanner alloc] initWithString:documentString];
    [documentScanner setCharactersToBeSkipped:nil];
    
    // uncolour the range
    [client resetColourInRange:effectiveRange];
    
    @try {
        for (NSInteger i = 0; i < kSMLCountOfSyntaxGroups; i++) {
            /* Colour all syntax groups */
            [self colourGroupWithIdentifier:i inRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
        }
    } @catch (NSException *exception) {
        NSLog(@"Syntax colouring exception: %@", exception);
    }

    return effectiveRange;
}


#pragma mark - Coloring passes


- (void)colourGroupWithIdentifier:(NSInteger)group inRange:(NSRange)effectiveRange withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSString *groupName;
    BOOL doColouring = YES;
    
    switch (group) {
        case kSMLSyntaxGroupNumber:
            groupName = SMLSyntaxGroupNumber;
            break;
        case kSMLSyntaxGroupCommand:
            groupName = SMLSyntaxGroupCommand;
            doColouring = ![self.syntaxDefinition.beginCommand isEqual:@""];
            break;
        case kSMLSyntaxGroupInstruction:
            groupName = SMLSyntaxGroupInstruction;
            doColouring = (![self.syntaxDefinition.beginInstruction isEqual:@""] || self.syntaxDefinition.instructions);
            break;
        case kSMLSyntaxGroupKeyword:
            groupName = SMLSyntaxGroupKeyword;
            doColouring = [self.syntaxDefinition.keywords count] > 0;
            break;
        case kSMLSyntaxGroupAutoComplete:
            groupName = SMLSyntaxGroupAutoComplete;
            doColouring = [self.syntaxDefinition.autocompleteWords count] > 0;
            break;
        case kSMLSyntaxGroupVariable:
            groupName = SMLSyntaxGroupVariable;
            doColouring = (self.syntaxDefinition.beginVariableCharacterSet || self.syntaxDefinition.variableRegex);
            break;
        case kSMLSyntaxGroupSecondString:
            groupName = SMLSyntaxGroupString;
            doColouring = ![self.syntaxDefinition.secondString isEqual:@""];
            break;
        case kSMLSyntaxGroupFirstString:
            groupName = SMLSyntaxGroupString;
            doColouring = ![self.syntaxDefinition.firstString isEqual:@""];
            break;
        case kSMLSyntaxGroupAttribute:
            groupName = SMLSyntaxGroupAttribute;
            break;
        case kSMLSyntaxGroupSingleLineComment:
            groupName = SMLSyntaxGroupComment;
            break;
        case kSMLSyntaxGroupMultiLineComment:
            groupName = SMLSyntaxGroupComment;
            break;
        case kSMLSyntaxGroupSecondStringPass2:
            groupName = SMLSyntaxGroupComment;
            doColouring = ![self.syntaxDefinition.secondString isEqual:@""];
            break;
        default:
            [NSException raise:@"Bug" format:@"Unrecognized syntax group identifier %ld", (long)group];
    }
    
    if (!doColouring) return;
    
    // reset scanner
    [rangeScanner mgs_setScanLocation:0];
    [documentScanner mgs_setScanLocation:0];
    
    switch (group) {
        case kSMLSyntaxGroupNumber:
            [self colourNumbersInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupCommand:
            [self colourCommandsInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupInstruction:
            [self colourInstructionsInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupKeyword:
            [self colourKeywordsInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupAutoComplete:
            [self colourAutocompleteInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupVariable:
            [self colourVariablesInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupSecondString:
            [self colourSecondStrings1InRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupFirstString:
            [self colourFirstStringsInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupAttribute:
            [self colourAttributesInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupSingleLineComment:
            [self colourSingleLineCommentsInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupMultiLineComment:
            [self colourMultiLineCommentsInRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
            break;
        case kSMLSyntaxGroupSecondStringPass2:
            [self colourSecondStrings2InRange:effectiveRange withRangeScanner:rangeScanner documentScanner:documentScanner];
    }
}


- (void)colourNumbersInRange:(NSRange)colouringRange withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSInteger colourStartLocation, colourEndLocation, queryLocation;
    NSInteger rangeLocation = colouringRange.location;
    unichar testCharacter;
    NSString *documentString = [documentScanner string];
    NSString *rangeString = [rangeScanner string];
    
    
    if (self.syntaxDefinition.numberDefinition) {
        [self recognizeMatchesOfPattern:self.syntaxDefinition.numberDefinition ofGroup:SMLSyntaxGroupNumber inString:documentString range:colouringRange];
        return;
    }
    
    
    // scan range to end
    while (![rangeScanner isAtEnd]) {
        
        // scan up to a number character
        [rangeScanner scanUpToCharactersFromSet:self.syntaxDefinition.numberCharacterSet intoString:NULL];
        colourStartLocation = [rangeScanner scanLocation];
        
        // scan to number end
        [rangeScanner scanCharactersFromSet:self.syntaxDefinition.numberCharacterSet intoString:NULL];
        colourEndLocation = [rangeScanner scanLocation];
        
        if (colourStartLocation == colourEndLocation) {
            break;
        }
        
        // don't colour if preceding character is a letter.
        // this prevents us from colouring numbers in variable names,
        queryLocation = colourStartLocation + rangeLocation;
        if (queryLocation > 0) {
            testCharacter = [documentString characterAtIndex:queryLocation - 1];
            
            // numbers can occur in variable, class and function names
            // eg: var_1 should not be coloured as a number
            if ([self.syntaxDefinition.nameCharacterSet characterIsMember:testCharacter]) {
                continue;
            }
        }
        
        // @todo: handle constructs such as 1..5 which may occur within some loop constructs
        
        // don't colour a trailing decimal point as some languages may use it as a line terminator
        if (colourEndLocation > 0) {
            queryLocation = colourEndLocation - 1;
            testCharacter = [rangeString characterAtIndex:queryLocation];
            if (testCharacter == self.syntaxDefinition.decimalPointCharacter) {
                colourEndLocation--;
            }
        }
        
        [self.client setGroup:SMLSyntaxGroupNumber forTokenInRange:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)];
    }
}


- (void)colourCommandsInRange:(NSRange)colouringRange withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSInteger colourStartLocation;
    NSInteger rangeLocation = colouringRange.location;
    NSUInteger endOfLine;
    NSInteger searchSyntaxLength = [self.syntaxDefinition.endCommand length];
    unichar beginCommandCharacter = [self.syntaxDefinition.beginCommand characterAtIndex:0];
    unichar endCommandCharacter = [self.syntaxDefinition.endCommand characterAtIndex:0];
    NSString *rangeString = [rangeScanner string];
    
    // reset scanner
    [rangeScanner mgs_setScanLocation:0];
    
    // scan range to end
    while (![rangeScanner isAtEnd]) {
        [rangeScanner scanUpToString:self.syntaxDefinition.beginCommand intoString:nil];
        colourStartLocation = [rangeScanner scanLocation];
        endOfLine = NSMaxRange([rangeString lineRangeForRange:NSMakeRange(colourStartLocation, 0)]);
        if (![rangeScanner scanUpToString:self.syntaxDefinition.endCommand intoString:nil] || [rangeScanner scanLocation] >= endOfLine) {
            [rangeScanner mgs_setScanLocation:endOfLine];
            continue; // Don't colour it if it hasn't got a closing tag
        } else {
            // To avoid problems with strings like <yada <%=yada%> yada> we need to balance the number of begin- and end-tags
            // If ever there's a beginCommand or endCommand with more than one character then do a check first
            NSUInteger commandLocation = colourStartLocation + 1;
            NSUInteger skipEndCommand = 0;
            
            while (commandLocation < endOfLine) {
                unichar commandCharacterTest = [rangeString characterAtIndex:commandLocation];
                if (commandCharacterTest == endCommandCharacter) {
                    if (!skipEndCommand) {
                        break;
                    } else {
                        skipEndCommand--;
                    }
                }
                if (commandCharacterTest == beginCommandCharacter) {
                    skipEndCommand++;
                }
                commandLocation++;
            }
            if (commandLocation < endOfLine) {
                [rangeScanner mgs_setScanLocation:commandLocation + searchSyntaxLength];
            } else {
                [rangeScanner mgs_setScanLocation:endOfLine];
            }
        }
        
        [self.client setGroup:SMLSyntaxGroupCommand forTokenInRange:NSMakeRange(colourStartLocation + rangeLocation, [rangeScanner scanLocation] - colourStartLocation)];
    }
}


- (void)colourInstructionsInRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSInteger colourStartLocation, beginLocationInMultiLine, endLocationInMultiLine;
    NSInteger rangeLocation = rangeToRecolour.location;
    NSRange searchRange;
    NSString *documentString = [documentScanner string];
    NSUInteger documentStringLength = [documentString length];
    NSUInteger maxRangeLocation = NSMaxRange(rangeToRecolour);
    
    if (self.syntaxDefinition.instructions) {
        [self recognizeKeywordsFromSet:self.syntaxDefinition.instructions ofGroup:SMLSyntaxGroupInstruction inRange:rangeToRecolour withRangeScanner:rangeScanner documentScanner:documentScanner];
        return;
    }
    
    // It takes too long to scan the whole document if it's large, so for instructions, first multi-line comment and second multi-line comment search backwards and begin at the start of the first beginInstruction etc. that it finds from the present position and, below, break the loop if it has passed the scanned range (i.e. after the end instruction)
    
    beginLocationInMultiLine = [documentString rangeOfString:self.syntaxDefinition.beginInstruction options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
    endLocationInMultiLine = [documentString rangeOfString:self.syntaxDefinition.endInstruction options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
    if (beginLocationInMultiLine == NSNotFound || (endLocationInMultiLine != NSNotFound && beginLocationInMultiLine < endLocationInMultiLine)) {
        beginLocationInMultiLine = rangeLocation;
    }
    
    NSInteger searchSyntaxLength = [self.syntaxDefinition.endInstruction length];
    
    // scan document to end
    while (![documentScanner isAtEnd]) {
        searchRange = NSMakeRange(beginLocationInMultiLine, rangeToRecolour.length);
        if (NSMaxRange(searchRange) > documentStringLength) {
            searchRange = NSMakeRange(beginLocationInMultiLine, documentStringLength - beginLocationInMultiLine);
        }
        
        colourStartLocation = [documentString rangeOfString:self.syntaxDefinition.beginInstruction options:NSLiteralSearch range:searchRange].location;
        if (colourStartLocation == NSNotFound) {
            break;
        }
        [documentScanner mgs_setScanLocation:colourStartLocation];
        if (![documentScanner scanUpToString:self.syntaxDefinition.endInstruction intoString:nil] || [documentScanner scanLocation] >= documentStringLength) {
            if (self.coloursOnlyUntilEndOfLine) {
                [documentScanner mgs_setScanLocation:NSMaxRange([documentString lineRangeForRange:NSMakeRange(colourStartLocation, 0)])];
            } else {
                [documentScanner mgs_setScanLocation:documentStringLength];
            }
        } else {
            if ([documentScanner scanLocation] + searchSyntaxLength <= documentStringLength) {
                [documentScanner mgs_setScanLocation:[documentScanner scanLocation] + searchSyntaxLength];
            }
        }
        
        [self.client setGroup:SMLSyntaxGroupInstruction forTokenInRange:NSMakeRange(colourStartLocation, [documentScanner scanLocation] - colourStartLocation)];
        if ([documentScanner scanLocation] > maxRangeLocation) {
            break;
        }
        beginLocationInMultiLine = [documentScanner scanLocation];
    }
}


- (void)colourKeywordsInRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    [self recognizeKeywordsFromSet:self.syntaxDefinition.keywords ofGroup:SMLSyntaxGroupKeyword inRange:rangeToRecolour withRangeScanner:rangeScanner documentScanner:documentScanner];
}


- (void)colourAutocompleteInRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    [self recognizeKeywordsFromSet:self.syntaxDefinition.autocompleteWords ofGroup:SMLSyntaxGroupAutoComplete inRange:rangeToRecolour withRangeScanner:rangeScanner documentScanner:documentScanner];
}


- (void)colourVariablesInRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSUInteger colourStartLocation;
    NSInteger rangeLocation = rangeToRecolour.location;
    NSUInteger endOfLine, colourLength;
    NSString *rangeString = [rangeScanner string];
    NSUInteger rangeStringLength = [rangeString length];
    
    if (self.syntaxDefinition.variableRegex) {
        [self recognizeMatchesOfPattern:self.syntaxDefinition.variableRegex ofGroup:SMLSyntaxGroupVariable inString:documentScanner.string range:rangeToRecolour];
        return;
    }
    
    // scan range to end
    while (![rangeScanner isAtEnd]) {
        [rangeScanner scanUpToCharactersFromSet:self.syntaxDefinition.beginVariableCharacterSet intoString:nil];
        colourStartLocation = [rangeScanner scanLocation];
        if (colourStartLocation + 1 < rangeStringLength) {
            if ([[self.syntaxDefinition.singleLineComments firstObject] isEqual:@"%"] && [rangeString characterAtIndex:colourStartLocation + 1] == '%') { // To avoid a problem in LaTex with \%
                if ([rangeScanner scanLocation] < rangeStringLength) {
                    [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                }
                continue;
            }
        }
        endOfLine = NSMaxRange([rangeString lineRangeForRange:NSMakeRange(colourStartLocation, 0)]);
        if (![rangeScanner scanUpToCharactersFromSet:self.syntaxDefinition.endVariableCharacterSet intoString:nil] || [rangeScanner scanLocation] >= endOfLine) {
            [rangeScanner mgs_setScanLocation:endOfLine];
            colourLength = [rangeScanner scanLocation] - colourStartLocation;
        } else {
            colourLength = [rangeScanner scanLocation] - colourStartLocation;
            if ([rangeScanner scanLocation] < rangeStringLength) {
                [rangeScanner mgs_setScanLocation:[rangeScanner scanLocation] + 1];
            }
        }
        
        [self.client setGroup:SMLSyntaxGroupVariable forTokenInRange:NSMakeRange(colourStartLocation + rangeLocation, colourLength)];
    }
}


- (void)colourSecondStrings1InRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSString *stringPattern;
    NSRegularExpression *regex;
    NSError *error;
    NSString *rangeString = [rangeScanner string];
    NSInteger rangeLocation = rangeToRecolour.location;
    
    if (!self.coloursMultiLineStrings)
        stringPattern = secondStringPattern;
    else
        stringPattern = secondMultilineStringPattern;
    
    regex = [NSRegularExpression regularExpressionWithPattern:stringPattern options:0 error:&error];
    if (error) return;
    
    [regex enumerateMatchesInString:rangeString options:0 range:NSMakeRange(0, [rangeString length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSRange foundRange = [match range];
        [self.client setGroup:SMLSyntaxGroupString forTokenInRange:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
    }];
}


- (void)colourFirstStringsInRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSString *stringPattern;
    NSRegularExpression *regex;
    NSError *error;
    NSString *rangeString = [rangeScanner string];
    NSInteger rangeLocation = rangeToRecolour.location;
    
    if (!self.coloursMultiLineStrings)
        stringPattern = firstStringPattern;
    else
        stringPattern = firstMultilineStringPattern;
    
    regex = [NSRegularExpression regularExpressionWithPattern:stringPattern options:0 error:&error];
    if (error) return;
    
    [regex enumerateMatchesInString:rangeString options:0 range:NSMakeRange(0, [rangeString length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSRange foundRange = [match range];
        if ([[self.client syntaxColouringGroupOfCharacterAtIndex:foundRange.location + rangeLocation] isEqual:@"strings"])
            return;
        [self.client setGroup:SMLSyntaxGroupString forTokenInRange:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
    }];
}


- (void)colourAttributesInRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSUInteger colourStartLocation, colourEndLocation;
    NSInteger rangeLocation = rangeToRecolour.location;
    NSString *documentString = [documentScanner string];
    NSString *rangeString = [rangeScanner string];
    NSUInteger rangeStringLength = [rangeString length];
    
    // scan range to end
    while (![rangeScanner isAtEnd]) {
        [rangeScanner scanUpToString:@" " intoString:nil];
        colourStartLocation = [rangeScanner scanLocation];
        if (colourStartLocation + 1 < rangeStringLength) {
            [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
        } else {
            break;
        }
        if (![[self.client syntaxColouringGroupOfCharacterAtIndex:(colourStartLocation + rangeLocation)] isEqual:SMLSyntaxGroupCommand]) {
            continue;
        }
        
        [rangeScanner scanCharactersFromSet:self.syntaxDefinition.attributesCharacterSet intoString:nil];
        colourEndLocation = [rangeScanner scanLocation];
        
        if (colourEndLocation + 1 < rangeStringLength) {
            [rangeScanner mgs_setScanLocation:[rangeScanner scanLocation] + 1];
        }
        
        if ([documentString characterAtIndex:colourEndLocation + rangeLocation] == '=') {
            [self.client setGroup:SMLSyntaxGroupAttribute forTokenInRange:NSMakeRange(colourStartLocation + rangeLocation, colourEndLocation - colourStartLocation)];
        }
    }
}


- (void)colourSingleLineCommentsInRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSUInteger colourStartLocation, endOfLine;
    NSRange rangeOfLine;
    NSInteger rangeLocation = rangeToRecolour.location;
    NSString *documentString = [documentScanner string];
    NSString *rangeString = [rangeScanner string];
    NSUInteger rangeStringLength = [rangeString length];
    NSUInteger documentStringLength = [documentString length];
    NSUInteger searchSyntaxLength;
    
    if (self.syntaxDefinition.singleLineCommentRegex) {
        [self recognizeMatchesOfPattern:self.syntaxDefinition.singleLineCommentRegex ofGroup:SMLSyntaxGroupComment inString:documentString range:rangeToRecolour];
        return;
    }
    
    for (NSString *singleLineComment in self.syntaxDefinition.singleLineComments) {
        if (![singleLineComment isEqualToString:@""]) {
            
            // reset scanner
            [rangeScanner mgs_setScanLocation:0];
            searchSyntaxLength = [singleLineComment length];
            
            // scan range to end
            while (![rangeScanner isAtEnd]) {
                
                // scan for comment
                [rangeScanner scanUpToString:singleLineComment intoString:nil];
                colourStartLocation = [rangeScanner scanLocation];
                
                // common case handling
                if ([singleLineComment isEqualToString:@"//"]) {
                    if (colourStartLocation > 0 && [rangeString characterAtIndex:colourStartLocation - 1] == ':') {
                        [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                        continue; // To avoid http:// ftp:// file:// etc.
                    }
                } else if ([singleLineComment isEqualToString:@"#"]) {
                    if (rangeStringLength > 1) {
                        rangeOfLine = [rangeString lineRangeForRange:NSMakeRange(colourStartLocation, 0)];
                        if ([rangeString rangeOfString:@"#!" options:NSLiteralSearch range:rangeOfLine].location != NSNotFound) {
                            [rangeScanner mgs_setScanLocation:NSMaxRange(rangeOfLine)];
                            continue; // Don't treat the line as a comment if it begins with #!
                        } else if (colourStartLocation > 0 && [rangeString characterAtIndex:colourStartLocation - 1] == '$') {
                            [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                            continue; // To avoid $#
                        } else if (colourStartLocation > 0 && [rangeString characterAtIndex:colourStartLocation - 1] == '&') {
                            [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                            continue; // To avoid &#
                        }
                    }
                } else if ([singleLineComment isEqualToString:@"%"]) {
                    if (rangeStringLength > 1) {
                        if (colourStartLocation > 0 && [rangeString characterAtIndex:colourStartLocation - 1] == '\\') {
                            [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                            continue; // To avoid \% in LaTex
                        }
                    }
                }
                
                // If the comment is within an already coloured string then disregard it
                if (colourStartLocation + rangeLocation + searchSyntaxLength < documentStringLength) {
                    if ([[self.client syntaxColouringGroupOfCharacterAtIndex:colourStartLocation + rangeLocation] isEqual:@"strings"]) {
                        [rangeScanner mgs_setScanLocation:colourStartLocation + 1];
                        continue;
                    }
                }
                
                // this is a single line comment so we can scan to the end of the line
                /* We omit the newline characters from the coloring area to
                 * avoid merging adjacent single-line comments that span the
                 * whole line. */
                [rangeString getLineStart:NULL end:NULL contentsEnd:&endOfLine forRange:NSMakeRange(colourStartLocation, 0)];
                [rangeScanner mgs_setScanLocation:endOfLine];
                
                // colour the comment
                [self.client setGroup:SMLSyntaxGroupComment forTokenInRange:NSMakeRange(colourStartLocation + rangeLocation, [rangeScanner scanLocation] - colourStartLocation)];
            }
        }
    } // end for
}


- (void)colourMultiLineCommentsInRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSUInteger colourStartLocation, beginLocationInMultiLine, endLocationInMultiLine, colourLength;
    NSRange searchRange;
    NSInteger rangeLocation = rangeToRecolour.location;
    NSString *documentString = [documentScanner string];
    NSUInteger documentStringLength = [documentString length];
    NSUInteger searchSyntaxLength;
    NSUInteger maxRangeLocation = NSMaxRange(rangeToRecolour);
    
    for (NSArray *multiLineComment in self.syntaxDefinition.multiLineComments) {
        
        // Get strings
        NSString *beginMultiLineComment = [multiLineComment objectAtIndex:0];
        NSString *endMultiLineComment = [multiLineComment objectAtIndex:1];
        
        if (![beginMultiLineComment isEqualToString:@""]) {
            
            // Default to start of document
            beginLocationInMultiLine = 0;
            
            // If start and end comment markers are the the same we
            // always start searching at the beginning of the document.
            // Otherwise we must consider that our start location may be mid way through
            // a multiline comment.
            if (![beginMultiLineComment isEqualToString:endMultiLineComment]) {
                
                // Search backwards from range location looking for comment start
                beginLocationInMultiLine = [documentString rangeOfString:beginMultiLineComment options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
                endLocationInMultiLine = [documentString rangeOfString:endMultiLineComment options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
                
                // If comments not found then begin at range location
                if (beginLocationInMultiLine == NSNotFound || (endLocationInMultiLine != NSNotFound && beginLocationInMultiLine < endLocationInMultiLine)) {
                    beginLocationInMultiLine = rangeLocation;
                }
            }
            
            [documentScanner mgs_setScanLocation:beginLocationInMultiLine];
            searchSyntaxLength = [endMultiLineComment length];
            
            // Iterate over the document until we exceed our work range
            while (![documentScanner isAtEnd]) {
                
                // Search up to document end
                searchRange = NSMakeRange(beginLocationInMultiLine, documentStringLength - beginLocationInMultiLine);
                
                // Look for comment start in document
                colourStartLocation = [documentString rangeOfString:beginMultiLineComment options:NSLiteralSearch range:searchRange].location;
                if (colourStartLocation == NSNotFound) {
                    break;
                }
                
                // Increment our location.
                // This is necessary to cover situations, such as F-Script, where the start and end comment strings are identical
                if (colourStartLocation + 1 < documentStringLength) {
                    [documentScanner mgs_setScanLocation:colourStartLocation + 1];
                    
                    // If the comment is within a string disregard it
                    if ([[self.client syntaxColouringGroupOfCharacterAtIndex:colourStartLocation] isEqual:@"strings"]) {
                        beginLocationInMultiLine++;
                        continue;
                    }
                } else {
                    [documentScanner mgs_setScanLocation:colourStartLocation];
                }
                
                // Scan up to comment end
                if (![documentScanner scanUpToString:endMultiLineComment intoString:nil] || [documentScanner scanLocation] >= documentStringLength) {
                    
                    // Comment end not found
                    if (self.coloursOnlyUntilEndOfLine) {
                        [documentScanner mgs_setScanLocation:NSMaxRange([documentString lineRangeForRange:NSMakeRange(colourStartLocation, 0)])];
                    } else {
                        [documentScanner mgs_setScanLocation:documentStringLength];
                    }
                    colourLength = [documentScanner scanLocation] - colourStartLocation;
                } else {
                    
                    // Comment end found
                    if ([documentScanner scanLocation] < documentStringLength) {
                        
                        // Safely advance scanner
                        [documentScanner mgs_setScanLocation:[documentScanner scanLocation] + searchSyntaxLength];
                    }
                    colourLength = [documentScanner scanLocation] - colourStartLocation;
                    
                    // HTML specific
                    if ([endMultiLineComment isEqualToString:@"-->"]) {
                        [documentScanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:nil]; // Search for the first letter after -->
                        if ([documentScanner scanLocation] + 6 < documentStringLength) {// Check if there's actually room for a </script>
                            if ([documentString rangeOfString:@"</script>" options:NSCaseInsensitiveSearch range:NSMakeRange([documentScanner scanLocation] - 2, 9)].location != NSNotFound || [documentString rangeOfString:@"</style>" options:NSCaseInsensitiveSearch range:NSMakeRange([documentScanner scanLocation] - 2, 8)].location != NSNotFound) {
                                beginLocationInMultiLine = [documentScanner scanLocation];
                                continue; // If the comment --> is followed by </script> or </style> it is probably not a real comment
                            }
                        }
                        [documentScanner mgs_setScanLocation:colourStartLocation + colourLength]; // Reset the scanner position
                    }
                }
                
                // Colour the range
                [self.client setGroup:SMLSyntaxGroupComment forTokenInRange:NSMakeRange(colourStartLocation, colourLength)];
                
                // We may be done
                if ([documentScanner scanLocation] > maxRangeLocation) {
                    break;
                }
                
                // set start location for next search
                beginLocationInMultiLine = [documentScanner scanLocation];
            }
        }
    } // end for
}


- (void)colourSecondStrings2InRange:(NSRange)rangeToRecolour withRangeScanner:(NSScanner*)rangeScanner documentScanner:(NSScanner*)documentScanner
{
    NSString *stringPattern;
    NSRegularExpression *regex;
    NSError *error;
    NSString *rangeString = [rangeScanner string];
    NSInteger rangeLocation = rangeToRecolour.location;
    
    if (!self.coloursMultiLineStrings)
        stringPattern = secondStringPattern;
    else
        stringPattern = secondMultilineStringPattern;
    
    regex = [NSRegularExpression regularExpressionWithPattern:stringPattern options:0 error:&error];
    if (error) return;
    
    [regex enumerateMatchesInString:rangeString options:0 range:NSMakeRange(0, [rangeString length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSRange foundRange = [match range];
        if ([[self.client syntaxColouringGroupOfCharacterAtIndex:foundRange.location + rangeLocation] isEqual:@"strings"] || [[self.client syntaxColouringGroupOfCharacterAtIndex:foundRange.location + rangeLocation] isEqual:@"comments"]) return;
        [self.client setGroup:SMLSyntaxGroupString forTokenInRange:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
    }];
}


@end
