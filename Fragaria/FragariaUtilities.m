//
//  FragariaUtilities.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 07/07/2019.
//

#import "FragariaUtilities.h"
#import "MGSAbstractSyntaxColouring.h"
#import "MGSColourScheme.h"


@interface MGSSimpleSyntaxColoring: MGSAbstractSyntaxColouring

@property (nonatomic, strong) NSMutableAttributedString *textStorage;

@end


@implementation MGSSimpleSyntaxColoring {
    NSMutableAttributedString *_textStorage;
}

@synthesize textStorage = _textStorage;

@end


void MGSHighlightAttributedString(NSMutableAttributedString *str, MGSSyntaxParser *parser, MGSColourScheme *scheme)
{
    if (str.length == 0)
        return;
    
    if (!scheme)
        scheme = [[MGSColourScheme alloc] init];
    
    NSFont *font = [str attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    MGSSimpleSyntaxColoring *colorer = [[MGSSimpleSyntaxColoring alloc] init];
    colorer.textStorage = str;
    colorer.parser = parser;
    colorer.colourScheme = scheme;
    colorer.textFont = font;
    [colorer recolourChangedRange:NSMakeRange(0, str.length)];
}



