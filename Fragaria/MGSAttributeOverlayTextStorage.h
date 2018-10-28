//
//  MGSAttributeOverlayTextStorage.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 28/10/2018.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MGSAttributeOverlayTextStorage : NSTextStorage

- (instancetype)initWithParentTextStorage:(NSTextStorage *)ts NS_DESIGNATED_INITIALIZER;

@property (readonly, strong) NSTextStorage *parentTextStorage;

@end

NS_ASSUME_NONNULL_END
