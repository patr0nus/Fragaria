//
//  MGSSyntaxParserClient.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 30/10/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/** Syntax groups are tags for identifying tokens in the text that must be
 *  coloured. */
typedef NSString * const SMLSyntaxGroup NS_STRING_ENUM;
extern SMLSyntaxGroup SMLSyntaxGroupNumber;
extern SMLSyntaxGroup SMLSyntaxGroupCommand;
extern SMLSyntaxGroup SMLSyntaxGroupInstruction;
extern SMLSyntaxGroup SMLSyntaxGroupKeyword;
extern SMLSyntaxGroup SMLSyntaxGroupAutoComplete;
extern SMLSyntaxGroup SMLSyntaxGroupVariable;
extern SMLSyntaxGroup SMLSyntaxGroupString;
extern SMLSyntaxGroup SMLSyntaxGroupAttribute;
extern SMLSyntaxGroup SMLSyntaxGroupComment;


/** MGSSyntaxParserClient specifies the methods used by MGSSyntaxParser
 *  to inspect existing parse results, and to apply the resulting tokenization
 *  to the text.
 *
 *  This protocol does not need to be implemented when creating a
 *  new parser; it is already implemented by an object internal to Fragaria which
 *  is passed to MGSSyntaxParser as needed. */
@protocol MGSSyntaxParserClient <NSObject>


#pragma mark - Creating Tokens
/// @name Creating Tokens


/** Removes any group assigned to the tokens in the specified range.
 *  @note Non-atomic tokens that cross the range boundary survive only outside the
 *    range specified. Atomic tokens crossing the range boundary are completely
 *    removed, even the part outside the range.
 *  @param range The range where to remove all token groups.
 *  @returns The range actually affected (includes the expansion caused by
 *    the occurrence of atomic tokens). */
- (NSRange)resetTokenGroupsInRange:(NSRange)range;

/** Creates a new token of the specified group for a range of the string
 *  being parsed.
 *  @note If the range includes (even partially) a preexisting atomic token,
 *    first the previously created token will be removed -- including the
 *    parts outside the range.
 *    If the range includes a non-atomic token, only the characters
 *    that are part of the range will change group to form a new token.
 *  @param group The syntax group of the new token.
 *  @param range The string range which will be assigned to the group, creating
 *     the token.
 *  @param atomic If the new token will be atomic. */
- (void)setGroup:(SMLSyntaxGroup)group forTokenInRange:(NSRange)range atomic:(BOOL)atomic;


#pragma mark - Inspecting Existing Tokens
/// @name Inspecting Existing Tokens


/** Searches if a token containing the character at the specified index exists.
 *  @note This method is faster than `-groupOfTokenAtCharacterIndex:`.
 *  @param index The index of a character in the token to search.
 *  @returns YES if a token is found, NO otherwise.  */
- (BOOL)existsTokenAtIndex:(NSUInteger)index;

/** Searches for the token containing the character at the specified index, then
 *  return its group.
 *  @param index The index of a character in the token to search.
 *  @returns The group of the token, or nil if no token was found. */
- (nullable SMLSyntaxGroup)groupOfTokenAtCharacterIndex:(NSUInteger)index;

/** Searches for the token containing the character at the specified index, then
 *  return its group and range in the string.
 *  @param index The index of a character in the token to search.
 *  @param atomic Optional pointer to a BOOL which will be assigned YES if an atomic
 *    token is found, or NO if a non-atomic token is found.
 *  @param range Optional pointer to an NSRange which will be assigned the range of
 *    the token in the text, if it is found.
 *  @returns The group of the token, or nil if no token was found. */
- (nullable SMLSyntaxGroup)groupOfTokenAtCharacterIndex:(NSUInteger)index isAtomic:(nullable BOOL *)atomic range:(nullable NSRangePointer)range;


@end


NS_ASSUME_NONNULL_END
