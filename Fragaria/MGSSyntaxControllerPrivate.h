//
//  MGSSyntaxControllerPrivate.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 24/12/2018.
//
/// @cond PRIVATE

#import "MGSSyntaxController.h"


@class MGSSyntaxParser;


@interface MGSSyntaxController ()


- (MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)syndef;


@end
