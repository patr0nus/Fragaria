//
//  MGSClassicFragariaParserFactory.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 27/12/2018.
//

#import <Foundation/Foundation.h>
#import "MGSParserFactory.h"

NS_ASSUME_NONNULL_BEGIN


@interface MGSClassicFragariaParserFactory : NSObject <MGSParserFactory>


+ (NSString *)standardSyntaxDefinitionName;


@end


NS_ASSUME_NONNULL_END
