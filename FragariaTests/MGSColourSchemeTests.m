//
//  MGSColourSchemeTests.m
//  Fragaria
//
//  Created by Jim Derry on 3/16/15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MGSMutableColourScheme.h"
#import "NSColor+TransformedCompare.h"
#import "MGSFragariaView.h"


NSColor *MGSTestRandomColor(void);


NSColor *MGSTestRandomColor(void)
{
    float r = arc4random_uniform(256) / 256.0;
    float g = arc4random_uniform(256) / 256.0;
    float b = arc4random_uniform(256) / 256.0;
    return [NSColor colorWithRed:r green:g blue:b alpha:1.0];
}


/**
 *  Basic tests for MGSColourScheme.
 **/
@interface MGSColourSchemeTests : XCTestCase

@end


@implementation MGSColourSchemeTests


/*
 * - setUp
 */
- (void)setUp
{
    [super setUp];
}


/*
 * - tearDown
 */
- (void)tearDown
{
    [super tearDown];
}


/*
 * - test_properties_to_file_and_back
 *   Make sure we can write a valid plist.
 */
- (void)test_propertiesToFile
{
    NSURL *tmpdir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSURL *outputPath;
	NSString *expects1 = @"Monty Python";
    NSColor *expects2 = [NSColor purpleColor];

    outputPath = [tmpdir URLByAppendingPathComponent:@"test_propertiesToFile.plist"];
	MGSMutableColourScheme *scheme = [[MGSMutableColourScheme alloc] init];
	scheme.displayName = expects1;
    [scheme setColour:expects2 forSyntaxGroup:MGSSyntaxGroupComment];
	
	XCTAssert([scheme writeToSchemeFileURL:outputPath error:nil]);
	
	scheme = [[MGSMutableColourScheme alloc] init];

	XCTAssert([scheme loadFromSchemeFileURL:outputPath error:nil]);
 
    [[NSFileManager defaultManager] removeItemAtURL:outputPath error:nil];
	
	XCTAssert([scheme.displayName isEqualToString:expects1]);
    XCTAssert([[scheme colourForSyntaxGroup:MGSSyntaxGroupComment] mgs_isEqualToColor:expects2 transformedThrough:@"MGSColourToPlainTextTransformer"]);
}


- (void)test_corruptFiles
{
    NSBundle *mybundle = [NSBundle bundleForClass:[self class]];
    NSArray <NSURL *> *testCases = @[
        [mybundle URLForResource:@"ColorScheme_WrongRootObject" withExtension:@"plist"],
        [mybundle URLForResource:@"ColorScheme_NotAPlist" withExtension:@"rtf"],
        [mybundle URLForResource:@"ColorScheme_WrongType1" withExtension:@"plist"],
        [mybundle URLForResource:@"ColorScheme_WrongType2" withExtension:@"plist"],
        [mybundle URLForResource:@"ColorScheme_WrongType3" withExtension:@"plist"]
    ];
    
    for (NSURL *url in testCases) {
        NSError *err;
        MGSMutableColourScheme *test = [[MGSMutableColourScheme alloc] initWithSchemeFileURL:url error:&err];
        XCTAssert(err && !test, @"invalid color scheme %@ did not fail to parse", url);
        NSLog(@"invalid file: %@; error: %@", url, err);
    }
}


/*
 * - test_initWithDictionary_simple
 */
- (void)test_initWithDictionary_simple
{
    NSString *expects = @"Autumn Noontime Moonlight";

    NSDictionary *testDict = @{ @"displayName" : expects };

    MGSMutableColourScheme *testInstance = [[MGSMutableColourScheme alloc] initWithDictionary:testDict];

    NSString *result = testInstance.displayName;

    XCTAssert([result isEqualToString:expects]);
}


/*
 * - test_isEqualToScheme
 */
- (void)test_isEqualToScheme
{
    NSColor *expects1 = [NSColor purpleColor];

    MGSMutableColourScheme *scheme1 = [[MGSMutableColourScheme alloc] init];
    MGSMutableColourScheme *scheme2 = [[MGSMutableColourScheme alloc] init];

    // Assert that they are equal.
    XCTAssert([scheme1 isEqualToScheme:scheme2]);

    [scheme1 setColour:expects1 forSyntaxGroup:MGSSyntaxGroupNumber];

    // Changing a color is detectable as a difference.
    XCTAssert(![scheme1 isEqualToScheme:scheme2]);

    [scheme2 setColour:expects1 forSyntaxGroup:MGSSyntaxGroupNumber];

    // Now equal again.
    XCTAssert([scheme1 isEqualToScheme:scheme2]);

    // Reset
    scheme1 = [[MGSMutableColourScheme alloc] init];
    scheme2 = [[MGSMutableColourScheme alloc] init];

    BOOL coloursStrings = [scheme1 coloursSyntaxGroup:MGSSyntaxGroupString];
    [scheme1 setColours:!coloursStrings syntaxGroup:MGSSyntaxGroupString];

    // Should be not the same.
    XCTAssert(![scheme1 isEqualToScheme:scheme2]);

    [scheme2 setColours:!coloursStrings syntaxGroup:MGSSyntaxGroupString];

    // Should be the same.
    XCTAssert([scheme1 isEqualToScheme:scheme2]);
}

/*
 * - test_isEqualToScheme_file
 *   Make sure isEqualToScheme works.
 */
- (void)test_isEqualToScheme_file
{
    NSURL *tmpdir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSURL *outputPath;
	NSString *expects1 = @"Pecans and Cashews";
	NSColor *expects2 = [NSColor purpleColor];
	
    outputPath = [tmpdir URLByAppendingPathComponent:@"test_isEqualToScheme_file.plist"];
    
	MGSMutableColourScheme *scheme = [[MGSMutableColourScheme alloc] init];
	scheme.displayName = expects1;
    [scheme setColour:expects2 forSyntaxGroup:MGSSyntaxGroupKeyword];
	
    NSError *err;
	[scheme writeToSchemeFileURL:outputPath error:&err];
    NSLog(@"%@", err);
	
	scheme = [[MGSMutableColourScheme alloc] init];
    err = nil;
	[scheme loadFromSchemeFileURL:outputPath error:&err];
    NSLog(@"%@", err);
	
	MGSMutableColourScheme *scheme2 = [[MGSMutableColourScheme alloc] initWithSchemeFileURL:outputPath error:nil];
 
    [[NSFileManager defaultManager] removeItemAtURL:outputPath error:nil];
	
	XCTAssert([scheme isEqualToScheme:scheme2]);
}

/*
 * - test_make_classic_fragaria_theme
 *   This test always passes, but makes a virgin Classic Fragaria.plist.
 */
- (void)test_make_classic_fragaria_theme
{
    NSURL *tmpdir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSURL *outputPath;
	
    outputPath = [tmpdir URLByAppendingPathComponent:@"Classic Fragaria.plist"];
    
	MGSMutableColourScheme *scheme = [[MGSMutableColourScheme alloc] init];
	scheme.displayName = @"Classic Fragaria";

	[scheme writeToSchemeFileURL:outputPath error:nil];
	
	XCTAssert(YES);
}


- (void)test_builtinColorSchemes
{
    NSArray <MGSColourScheme *> *schemes = [MGSMutableColourScheme builtinColourSchemes];
    NSLog(@"builtins loaded are %@", schemes);
    XCTAssert(schemes);
}


- (void)test_groupResolution
{
    MGSMutableColourScheme *cs = [[MGSMutableColourScheme alloc] init];
    XCTAssertEqualObjects(MGSSyntaxGroupNumber, [cs resolveSyntaxGroup:MGSSyntaxGroupNumber]);
    XCTAssertEqualObjects(MGSSyntaxGroupNumber, [cs resolveSyntaxGroup:@"number.test"]);
    XCTAssertEqualObjects(nil, [cs resolveSyntaxGroup:@"nonexistent"]);
    [cs setColour:[NSColor redColor] forSyntaxGroup:@"strings.example"];
    XCTAssertEqualObjects(@"strings.example", [cs resolveSyntaxGroup:@"strings.example.nonexistent"]);
    XCTAssertEqualObjects(@"strings.example", [cs resolveSyntaxGroup:@"strings.example"]);
    XCTAssertEqualObjects(MGSSyntaxGroupString, [cs resolveSyntaxGroup:@"strings"]);
    XCTAssertEqualObjects(MGSSyntaxGroupString, [cs resolveSyntaxGroup:@"strings.nonexistent"]);
}


@end
