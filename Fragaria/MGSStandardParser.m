//
//  MGSStandardParser.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 27/04/2019.
//

#import "MGSStandardParser.h"


@implementation MGSStandardParser


+ (NSString *)standardSyntaxDefinitionName
{
    return @"Standard";
}


- (NSArray *)syntaxDefinitionNames
{
    return @[[[self class] standardSyntaxDefinitionName]];
}


- (nonnull MGSSyntaxParser *)parserForSyntaxDefinitionName:(nonnull NSString *)syndef
{
    return self;
}


- (NSRange)parseForClient:(id<MGSSyntaxParserClient>)client
{
    return NSMakeRange(0, client.stringToParse.length);
}


@end
