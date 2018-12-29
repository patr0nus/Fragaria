//
//  MGSSyntaxParserClient.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 30/10/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


// syntax colouring group names
extern NSString *SMLSyntaxGroupNumber;
extern NSString *SMLSyntaxGroupCommand;
extern NSString *SMLSyntaxGroupInstruction;
extern NSString *SMLSyntaxGroupKeyword;
extern NSString *SMLSyntaxGroupAutoComplete;
extern NSString *SMLSyntaxGroupVariable;
extern NSString *SMLSyntaxGroupString;
extern NSString *SMLSyntaxGroupAttribute;
extern NSString *SMLSyntaxGroupComment;


@protocol MGSSyntaxParserClient <NSObject>


- (NSRange)resetTokenGroupsInRange:(NSRange)range;

- (void)setGroup:(SMLSyntaxGroup)group forTokenInRange:(NSRange)range atomic:(BOOL)atomic;

- (nullable SMLSyntaxGroup)groupOfTokenAtCharacterIndex:(NSUInteger)index isAtomic:(nullable BOOL *)atomic;

- (BOOL)existsTokenAtIndex:(NSUInteger)index range:(NSRangePointer)res;


@end


NS_ASSUME_NONNULL_END
