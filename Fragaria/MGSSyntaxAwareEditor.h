//
//  MGSSyntaxAwareEditor.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 01/12/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@protocol MGSSyntaxAwareEditor <NSObject>


@property (readonly, nonatomic) BOOL providesCommentOrUncomment;


@optional

- (void)commentOrUncomment:(NSMutableString *)string;


@end


NS_ASSUME_NONNULL_END
