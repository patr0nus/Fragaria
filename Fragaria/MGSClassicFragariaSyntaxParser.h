//
//  MGSClassicFragariaSyntaxParser.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 27/12/2018.
//

#import "MGSSyntaxParser.h"

NS_ASSUME_NONNULL_BEGIN


@class MGSClassicFragariaSyntaxDefinition;


@interface MGSClassicFragariaSyntaxParser : MGSSyntaxParser


- (instancetype)initWithSyntaxDefinition:(MGSClassicFragariaSyntaxDefinition *)sdef;

@property (nonatomic, readonly) MGSClassicFragariaSyntaxDefinition *syntaxDefinition;


@end


NS_ASSUME_NONNULL_END
