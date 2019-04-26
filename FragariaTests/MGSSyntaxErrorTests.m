//
//  MGSSyntaxErrorTests.m
//  Fragaria
//
//  Created by Jim Derry on 2/16/15.
//
//

#import <Cocoa/Cocoa.h>
#import "MGSSyntaxError.h"
#import <XCTest/XCTest.h>

/**
 *  Provides some testing for MGSSyntaxError class.
 **/
@interface MGSSyntaxErrorTests : XCTestCase

@property (nonatomic,strong) NSArray *syntaxErrors;

@end


@implementation MGSSyntaxErrorTests

/*
 *  - setup
 *    Populate self.syntax errors with sample errors for each test.
 */
- (void)setUp {
    [super setUp];
	self.syntaxErrors = @[
						  [MGSSyntaxError errorWithDictionary:@{
																@"errorDescription" : @"Sample error 1.",
																@"line" : @(4),
																@"hidden" : @(NO),
																@"warningLevel" : @(kMGSErrorCategoryAccess)
																}],
						  
						  [MGSSyntaxError errorWithDictionary:@{
																@"errorDescription" : @"Sample error 2.",
																@"line" : @(4),
																@"hidden" : @(YES),
																@"warningLevel" : @(601.223) // panic
																}],
						  [MGSSyntaxError errorWithDescription:@"Sample error 3."
                                                       ofLevel:kMGSErrorCategoryDocument
                                                        atLine:37],
						  [MGSSyntaxError errorWithDictionary:@{
																@"errorDescription" : @"Sample error 4.",
																@"line" : @(37),
																@"hidden" : @(NO),
																@"warningLevel" : @(kMGSErrorCategoryDocument)
																}],
						  [MGSSyntaxError errorWithDictionary:@{
																@"errorDescription" : @"Sample error 5.",
																@"line" : @(189),
																@"hidden" : @(NO),
																@"warningLevel" : @(522.2)
																}],
						  [MGSSyntaxError errorWithDictionary:@{
																@"errorDescription" : @"Sample error 6.",
																@"line" : @(212),
																@"hidden" : @(YES),
																}],
						  ];
}


/*
 *  - teardown
 */
- (void)tearDown {
    [super tearDown];
}


/*
 *  - test_defaultImagesForWarningLevel
 *    Here we want to ensure that if an image isn't specified, the correct
 *    default image is supplied based on the warningLevel property.
 */
- (void)test_defaultImageForWarningLevel
{
	MGSSyntaxError *test;
	NSImage *result;
	NSImage *expect;
	
	// Tests values over 600
	test = self.syntaxErrors[1];
	result = [MGSSyntaxError defaultImageForWarningLevel:test.warningLevel];
	expect = [[NSBundle bundleForClass:[MGSSyntaxError class]] imageForResource:@"messagesPanic"];
	XCTAssert([[result TIFFRepresentation] isEqualToData:[expect TIFFRepresentation]]);

	// Tests the default value
	test = self.syntaxErrors[5];
	result = [MGSSyntaxError defaultImageForWarningLevel:test.warningLevel];
	expect = [[NSBundle bundleForClass:[MGSSyntaxError class]] imageForResource:@"messagesWarning"];
	XCTAssert([[result TIFFRepresentation] isEqualToData:[expect TIFFRepresentation]]);
	
	// Tests a standard case where the value is not exact.
	test = self.syntaxErrors[4];
	result = [MGSSyntaxError defaultImageForWarningLevel:test.warningLevel];
	expect = [[NSBundle bundleForClass:[MGSSyntaxError class]] imageForResource:@"messagesError"];
	XCTAssert([[result TIFFRepresentation] isEqualToData:[expect TIFFRepresentation]]);

	// Tests the default case where the value is exact.
	test = self.syntaxErrors[3];
	result = [MGSSyntaxError defaultImageForWarningLevel:test.warningLevel];
	expect = [[NSBundle bundleForClass:[MGSSyntaxError class]] imageForResource:@"messagesDocument"];
	XCTAssert([[result TIFFRepresentation] isEqualToData:[expect TIFFRepresentation]]);
}


@end
