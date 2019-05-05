//
//  MGSSyntaxControllerTests.m
//  Fragaria Tests
//
//  Created by Daniele Cattaneo on 04/05/2019.
//

#import <XCTest/XCTest.h>
#import <Fragaria/Fragaria.h>


@interface MGSSyntaxController ()

- (instancetype)_init;

@end


@interface TestParserFactory : MGSSyntaxParser <MGSParserFactory>

@property (nonatomic, strong) NSArray *syntaxDefinitionNames;
@property (nonatomic, strong) NSDictionary <NSString*, NSArray*> *extensions;
@property (nonatomic, strong) NSDictionary <NSString*, NSArray*> *utis;
@property (nonatomic, strong) NSDictionary <NSString*, NSArray*> *firstLines;
@property (nonatomic, strong) NSDictionary <NSString*, NSString*> *localizedSyntaxGroups;

@end


@implementation TestParserFactory


- (nonnull MGSSyntaxParser *)parserForSyntaxDefinitionName:(nonnull NSString *)syndef
{
    if (![self.syntaxDefinitionNames containsObject:syndef])
        [NSException raise:@"TestFailure" format:@"wrong name"];
    return self;
}


- (NSArray <NSString *> *)syntaxDefinitionNamesWithExtension:(NSString *)extension
{
    __block NSMutableArray *res = [NSMutableArray array];
    [self.extensions enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *obj, BOOL *stop) {
        if ([obj containsObject:extension])
            [res addObject:key];
    }];
    return [res copy];
}


- (NSArray <NSString *> *)extensionsForSyntaxDefinitionName:(NSString *)sdname
{
    if (![self.syntaxDefinitionNames containsObject:sdname])
        [NSException raise:@"TestFailure" format:@"wrong name"];
    return [self.extensions objectForKey:sdname] ?: @[];
}


- (NSArray <NSString *> *)syntaxDefinitionNamesWithUTI:(NSString *)uti
{
    __block NSMutableArray *res = [NSMutableArray array];
    [self.utis enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *obj, BOOL *stop) {
        if ([obj containsObject:uti])
            [res addObject:key];
    }];
    return [res copy];
}


- (NSArray <NSString *> *)guessSyntaxDefinitionNamesFromFirstLine:(NSString *)firstLine
{
    __block NSMutableArray *res = [NSMutableArray array];
    [self.firstLines enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *obj, BOOL *stop) {
        if ([obj containsObject:firstLine])
            [res addObject:key];
    }];
    return [res copy];
}


- (NSArray<MGSSyntaxGroup> *)syntaxGroupsForParsers
{
    return self.localizedSyntaxGroups.allKeys;
}


- (nullable NSString *)localizedDisplayNameForSyntaxGroup:(MGSSyntaxGroup)syntaxGroup
{
    NSString *res = [self.localizedSyntaxGroups objectForKey:syntaxGroup];
    if (!res)
        [NSException raise:@"TestFailure" format:@"wrong group"];
    return res;
}


@end


@interface MGSSyntaxControllerTests : XCTestCase

@end


@implementation MGSSyntaxControllerTests


- (void)setUp
{
    [super setUp];
}


- (void)tearDown
{
    [super tearDown];
}


- (BOOL)checkArray:(NSArray *)check isPermutationOfArray:(NSArray *)expect
{
    NSMutableArray *left = [check mutableCopy];
    for (id obj in expect) {
        NSInteger i = [left indexOfObject:obj];
        if (i == NSNotFound)
            return NO;
        [left removeObjectAtIndex:i];
    }
    if (left.count != 0)
        return NO;
    return YES;
}


- (void)testStandardSyntaxDefinitionExists
{
    NSString *stddef = [MGSSyntaxController standardSyntaxDefinitionName];
    MGSSyntaxController *sc = [[MGSSyntaxController alloc] _init];
    
    XCTAssertNotNil(stddef, @"standard syntax def name must not be nil");
    XCTAssertNotEqualObjects(stddef, @"", @"standard syntax def name must not be the empty string");
    
    XCTAssertTrue([[sc syntaxDefinitionNames] containsObject:stddef], @"standard syntax def must be in the syntax def list");
    XCTAssertEqualObjects(@[], [sc extensionsForSyntaxDefinitionName:stddef], @"standard syntax def is documented to not have any extension associated");
    XCTAssertNotNil([sc parserForSyntaxDefinitionName:stddef], @"standard syntax def should have a parser");
}


- (void)testNoneSyntaxDefinitionExists
{
    NSString *stddef = @"None";
    MGSSyntaxController *sc = [[MGSSyntaxController alloc] _init];
    
    XCTAssertTrue([[sc syntaxDefinitionNames] containsObject:stddef]);
    XCTAssertEqualObjects(@[@"txt"], [sc extensionsForSyntaxDefinitionName:stddef]);
    XCTAssertEqualObjects(@[@"None"], [sc syntaxDefinitionNamesWithExtension:@"txt"]);
    XCTAssertEqualObjects(@[@"None"], [sc syntaxDefinitionNamesWithUTI:@"public.plain-text"]);
    
    XCTAssertNotNil([sc parserForSyntaxDefinitionName:stddef]);
}


- (void)testCustomParserFactory
{
    MGSSyntaxController *sc = [[MGSSyntaxController alloc] _init];
    NSArray *prevSdList = [sc syntaxDefinitionNames];
    NSArray *prevGrpList = [sc syntaxGroupsForParsers];
    
    TestParserFactory *pf = [[TestParserFactory alloc] init];
    pf.syntaxDefinitionNames = @[@"TestParserFactory"];
    pf.extensions = @{@"TestParserFactory": @[@"TestParserFactory_ext"]};
    pf.utis = @{@"TestParserFactory": @[@"uti.TestParserFactory"]};
    pf.firstLines = @{@"TestParserFactory": @[@"Test First Line"]};
    pf.localizedSyntaxGroups = @{@"test.group": @"Test Group"};
    [sc registerParserFactory:pf];
    
    NSArray *newSdList = [sc syntaxDefinitionNames];
    XCTAssertTrue([self checkArray:newSdList isPermutationOfArray:[prevSdList arrayByAddingObject:@"TestParserFactory"]]);
    
    NSArray *newGrpList = [sc syntaxGroupsForParsers];
    NSMutableArray *diffGrpList = [newGrpList mutableCopy];
    [diffGrpList removeObjectsInArray:prevGrpList];
    XCTAssertTrue([diffGrpList isEqual:@[@"test.group"]]);
    
    XCTAssertEqualObjects(pf, [sc parserForSyntaxDefinitionName:@"TestParserFactory"]);
    
    XCTAssertEqualObjects((@[]), [sc syntaxDefinitionNamesWithExtension:@"unrecognized-ext"]);
    XCTAssertEqualObjects((@[@"TestParserFactory"]), [sc syntaxDefinitionNamesWithExtension:@"TestParserFactory_ext"]);
    
    XCTAssertNoThrow([sc extensionsForSyntaxDefinitionName:@"TestParserFactory"]);
    XCTAssertEqualObjects(@[@"TestParserFactory_ext"], [sc extensionsForSyntaxDefinitionName:@"TestParserFactory"]);
    
    XCTAssertEqualObjects(@[@"TestParserFactory"], [sc syntaxDefinitionNamesWithUTI:@"uti.TestParserFactory"]);
    
    XCTAssertEqualObjects(@[@"TestParserFactory"], [sc guessSyntaxDefinitionNamesFromFirstLine:@"Test First Line"]);
    
    XCTAssertNoThrow([sc localizedDisplayNameForSyntaxGroup:MGSSyntaxGroupNumber]);
    XCTAssertEqualObjects(@"Test Group", [sc localizedDisplayNameForSyntaxGroup:@"test.group"]);
}


- (void)testNonExistentIdentifiers
{
    MGSSyntaxController *sc = [[MGSSyntaxController alloc] _init];
    
    XCTAssertEqualObjects(@[], [sc syntaxDefinitionNamesWithExtension:@"unsupported-ext"]);
    XCTAssertEqualObjects(@[], [sc extensionsForSyntaxDefinitionName:@"unsupported-syntax-def"]);
    XCTAssertEqualObjects(@[], [sc syntaxDefinitionNamesWithUTI:@"uti.which.does.not.exist"]);
    XCTAssertEqualObjects(@[], [sc guessSyntaxDefinitionNamesFromFirstLine:@"the first line of a plain text file"]);
    XCTAssertNil([sc parserForSyntaxDefinitionName:@"unsupported-syntax-def"]);
    XCTAssertEqualObjects(@"inexistent.syntax.group", [sc localizedDisplayNameForSyntaxGroup:@"inexistent.syntax.group"]);
}


- (void)testInitReturnsSingleton
{
    MGSSyntaxController *sc = [MGSSyntaxController sharedInstance];
    XCTAssertEqualObjects(sc, [[MGSSyntaxController alloc] init]);
}


- (void)testSyntaxDefinitionNameListConsistency
{
    MGSSyntaxController *sc = [[MGSSyntaxController alloc] _init];
    NSArray *sdl1 = [sc syntaxDefinitionNames];
    NSArray *sdl2 = [sc syntaxDefinitionNames];
    XCTAssertEqualObjects(sdl1, sdl2);
}


- (void)testDuplicatedSyntaxDefinition
{
    MGSSyntaxController *sc = [[MGSSyntaxController alloc] _init];
    NSArray *prevSdList = [sc syntaxDefinitionNames];
    
    TestParserFactory *pf = [[TestParserFactory alloc] init];
    pf.syntaxDefinitionNames = @[@"None"];
    pf.extensions = @{@"None": @[@"not_txt"]};
    pf.utis = @{@"None": @[@"not-public.not-plain-text"]};
    pf.firstLines = @{@"None": @[@"We Have A First Line"]};
    [sc registerParserFactory:pf];
    
    TestParserFactory *pf2 = [[TestParserFactory alloc] init];
    pf2.syntaxDefinitionNames = @[@"None"];
    pf2.extensions = @{@"None": @[@"not_txt2"]};
    pf2.utis = @{@"None": @[@"not-public.not-plain-text2"]};
    pf2.firstLines = @{@"None": @[@"We Have A First Line 2"]};
    [sc registerParserFactory:pf2];
    
    NSArray *newSdList = [sc syntaxDefinitionNames];
    NSArray *expectedSdList = [prevSdList arrayByAddingObjectsFromArray:@[@"None (1)", @"None (2)"]];
    XCTAssertTrue([self checkArray:newSdList isPermutationOfArray:expectedSdList]);
    
    XCTAssertEqualObjects(pf, [sc parserForSyntaxDefinitionName:@"None (1)"]);
    XCTAssertEqualObjects(pf2, [sc parserForSyntaxDefinitionName:@"None (2)"]);
    
    XCTAssertEqualObjects((@[@"None"]), [sc syntaxDefinitionNamesWithExtension:@"txt"]);
    XCTAssertEqualObjects((@[@"None (1)"]), [sc syntaxDefinitionNamesWithExtension:@"not_txt"]);
    XCTAssertEqualObjects((@[@"None (2)"]), [sc syntaxDefinitionNamesWithExtension:@"not_txt2"]);
    
    XCTAssertEqualObjects(@[@"txt"], [sc extensionsForSyntaxDefinitionName:@"None"]);
    XCTAssertEqualObjects(@[@"not_txt"], [sc extensionsForSyntaxDefinitionName:@"None (1)"]);
    XCTAssertEqualObjects(@[@"not_txt2"], [sc extensionsForSyntaxDefinitionName:@"None (2)"]);
    
    XCTAssertEqualObjects(@[@"None"], [sc syntaxDefinitionNamesWithUTI:@"public.plain-text"]);
    XCTAssertEqualObjects(@[@"None (1)"], [sc syntaxDefinitionNamesWithUTI:@"not-public.not-plain-text"]);
    XCTAssertEqualObjects(@[@"None (2)"], [sc syntaxDefinitionNamesWithUTI:@"not-public.not-plain-text2"]);
    
    XCTAssertEqualObjects(@[@"None (1)"], [sc guessSyntaxDefinitionNamesFromFirstLine:@"We Have A First Line"]);
    XCTAssertEqualObjects(@[@"None (2)"], [sc guessSyntaxDefinitionNamesFromFirstLine:@"We Have A First Line 2"]);
}


@end
