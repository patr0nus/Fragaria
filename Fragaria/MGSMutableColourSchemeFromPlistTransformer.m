//
//  MGSMutableColourSchemeFromPlistTransformer.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 03/07/2019.
//

#import "MGSMutableColourSchemeFromPlistTransformer.h"
#import "MGSMutableColourScheme.h"


NSValueTransformerName const MGSMutableColourSchemeFromPlistTransformerName = @"MGSMutableColourSchemeFromPlistTransformer";


@implementation MGSMutableColourSchemeFromPlistTransformer


+ (void)load
{
    MGSMutableColourSchemeFromPlistTransformer *reg = [[MGSMutableColourSchemeFromPlistTransformer alloc] init];
    [NSValueTransformer setValueTransformer:reg forName:MGSMutableColourSchemeFromPlistTransformerName];
}


+ (Class)transformedValueClass
{
    return [MGSMutableColourScheme class];
}


+ (BOOL)allowsReverseTransformation
{
    return YES;
}


- (id)transformedValue:(id)value
{
    if (!value || ![value isKindOfClass:[NSDictionary class]])
        return nil;
    return [[MGSMutableColourScheme alloc] initWithPropertyList:value error:nil];
}


- (id)reverseTransformedValue:(id)value
{
    if (!value || ![value isKindOfClass:[MGSColourScheme class]])
        return nil;
    return [value propertyListRepresentation];
}


@end
