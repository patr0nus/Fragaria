//
//  NSCharacterSet+Fragaria.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 25/04/2019.
//

#import "NSCharacterSet+Fragaria.h"


@implementation NSCharacterSet (Fragaria)


- (BOOL)isEmpty
{
    return [self isEqual:[NSCharacterSet characterSetWithCharactersInString:@""]];
}


@end
