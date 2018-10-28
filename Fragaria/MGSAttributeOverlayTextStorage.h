//
//  MGSAttributeOverlayTextStorage.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 28/10/2018.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN


/** An implementation of NSTextStorage as a view of another text storage's
 *  text but with different attributes.
 *
 *  Any change on the text of this text storage will be reflected to the parent
 *  text storage and vice versa. Changes on the attributes of the parent text
 *  storage will be reflected on this text storage if there is not an attribute
 *  set on this text storage which overrides it. Changes on the attributes of
 *  this text storage do not reflect to changes in the attributes of the parent
 *  text storage.
 *
 *  @note At the moment the implementation actually stores its private attributes
 *     on the parent text storage, instead of having its own attribute storage. */
@interface MGSAttributeOverlayTextStorage : NSTextStorage


/** Initializes this text storage as a view of the specified text storage.
 *  @param ts The parent text storage
 *  @returns A new instance of MGSAttributeOverlayTextStorage. */
- (instancetype)initWithParentTextStorage:(NSTextStorage *)ts NS_DESIGNATED_INITIALIZER;

/** The text storage which is the parent of this text storage. */
@property (readonly, strong) NSTextStorage *parentTextStorage;


@end


NS_ASSUME_NONNULL_END
