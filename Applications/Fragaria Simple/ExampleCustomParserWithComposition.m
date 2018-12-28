//
//  ExampleCustomParserWithComposition.m
//  Fragaria Simple
//
//  Created by Daniele Cattaneo on 28/12/2018.
//

#import "ExampleCustomParserWithComposition.h"


@implementation ExampleCustomParserWithComposition
{
    MGSSyntaxParser *objcParser;
}


- (instancetype)init
{
    self = [super init];
    objcParser = [[MGSSyntaxController sharedInstance] parserForSyntaxDefinitionName:@"Objective-C"];
    if (!objcParser) {
        NSLog(@"Where's my standard objc parser!?");
        return nil;
    }
    return self;
}


- (NSArray *)syntaxDefinitionNames
{
    return @[@"Objective-C Plus"];
}


- (nonnull MGSSyntaxParser *)parserForSyntaxDefinitionName:(nonnull NSString *)syndef
{
    /* Note that calling -parserForSyntaxDefinitionName: on [MGSSyntaxController sharedInstance]
     * inside the implementation of -parserForSyntaxDefinitionName: on a parser factory
     * is fully supported, as long as it does not cause a recursion
     * inside your parser factory code. */
    return self;
}


- (NSRange)parseString:(NSString *)string inRange:(NSRange)range forParserClient:(id<MGSSyntaxParserClient>)client
{
    /* Color as a command every word starting with NS */
    NSRange realRange = [objcParser parseString:string inRange:range forParserClient:client];
    
    [string enumerateSubstringsInRange:realRange options:NSStringEnumerationByWords usingBlock:
    ^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        /* Ignore whatever is inside a string */
        NSString *g = [client groupOfTokenAtCharacterIndex:substringRange.location];
        if ([SMLSyntaxGroupString isEqual:g])
            return;
        
        if ([substring length] > 0 && [substring hasPrefix:@"NS"]) {
            [client setGroup:SMLSyntaxGroupCommand forTokenInRange:substringRange];
        }
    }];
    
    return realRange;
}


@end
