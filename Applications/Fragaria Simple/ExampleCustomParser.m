//
//  ExampleCustomParser.m
//  Fragaria Simple
//
//  Created by Daniele Cattaneo on 28/12/2018.
//

#import "ExampleCustomParser.h"


@implementation ExampleCustomParser


- (NSArray *)syntaxDefinitionNames
{
    return @[@"Example Custom Parser"];
}


- (nonnull MGSSyntaxParser *)parserForSyntaxDefinitionName:(nonnull NSString *)syndef
{
    return self;
}


- (NSRange)parseString:(NSString *)string inRange:(NSRange)range forParserClient:(id<MGSSyntaxParserClient>)client
{
    /* Color as an instruction every word starting with an uppercase letter */
    NSRange realRange = [string lineRangeForRange:range];
    [client resetTokenGroupsInRange:realRange];
    
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    [string enumerateSubstringsInRange:realRange options:NSStringEnumerationByWords usingBlock:
    ^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if ([substring length] > 0 && [uppercase characterIsMember:[substring characterAtIndex:0]]) {
            [client setGroup:SMLSyntaxGroupInstruction forTokenInRange:substringRange atomic:YES];
        }
    }];
    
    return realRange;
}


@end
