//
//  MGSAttributeOverlayTextStorage.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 28/10/2018.
//

#import "MGSAttributeOverlayTextStorage.h"


static NSString * const MGSAttributeOverlayPrefixBase = @"__MGSAttributeOverlay_";


@interface MGSAttributeOverlayTextStorage ()

@property (readonly) NSString *overlayAttributePrefix;

@end


@implementation MGSAttributeOverlayTextStorage
{
    BOOL editInProgress;
    BOOL parentEditInProgress;
}


- (instancetype)initWithParentTextStorage:(NSTextStorage *)ts
{
    self = [super init];
    
    _parentTextStorage = ts;
    _overlayAttributePrefix = [NSString stringWithFormat:@"%@%p_", MGSAttributeOverlayPrefixBase, self];
    
    editInProgress = NO;
    parentEditInProgress = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentTextStorageDidProcessEdit:) name:NSTextStorageDidProcessEditingNotification object:ts];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentTextStorageWillProcessEdit:) name:NSTextStorageWillProcessEditingNotification object:ts];
    
    return self;
}


- (instancetype)init
{
    NSTextStorage *backingStore = [[NSTextStorage alloc] init];
    return [self initWithParentTextStorage:backingStore];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSString *)string
{
    return self.parentTextStorage.string;
}


- (void)parentTextStorageWillProcessEdit:(NSNotification *)notif
{
    if (editInProgress)
        return;
    
    parentEditInProgress = YES;
    
    NSNotification *mynotif = [NSNotification notificationWithName:NSTextStorageWillProcessEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotification:mynotif];
    /* The textStorageWillProcessEditing: old-style delegate method is already handled by
     * NSTextStorage by registering the delegate for the NSTextStorageWillProcessEditingNotification
     * notification on assignment of the delegate property */
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(textStorage:willProcessEditing:range:changeInLength:)]) {
        [self.delegate textStorage:self willProcessEditing:self.editedMask range:self.editedRange changeInLength:self.changeInLength];
    }
    
    parentEditInProgress = NO;
}


- (void)parentTextStorageDidProcessEdit:(NSNotification *)notif
{
    if (editInProgress)
        return;
    
    parentEditInProgress = YES;
    
    NSNotification *mynotif = [NSNotification notificationWithName:NSTextStorageDidProcessEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotification:mynotif];
    /* The textStorageDidProcessEditing: old-style delegate method is already handled by
     * NSTextStorage by registering the delegate for the NSTextStorageDidProcessEditingNotification
     * notification on assignment of the delegate property */
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(textStorage:didProcessEditing:range:changeInLength:)]) {
        [self.delegate textStorage:self didProcessEditing:self.editedMask range:self.editedRange changeInLength:self.changeInLength];
    }
    
    parentEditInProgress = NO;
}


- (NSTextStorageEditActions)editedMask
{
    if (parentEditInProgress)
        return self.parentTextStorage.editedMask;
    return super.editedMask;
}


- (NSRange)editedRange
{
    if (parentEditInProgress)
        return self.parentTextStorage.editedRange;
    return super.editedRange;
}


- (NSInteger)changeInLength
{
    if (parentEditInProgress)
        return self.parentTextStorage.changeInLength;
    return super.changeInLength;
}


- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    NSDictionary *attrib = [self.parentTextStorage attributesAtIndex:location effectiveRange:range];
    NSMutableDictionary *base = [NSMutableDictionary dictionary];
    NSMutableDictionary *ovl = [NSMutableDictionary dictionary];
    
    [attrib enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key hasPrefix:MGSAttributeOverlayPrefixBase]) {
            [base setObject:obj forKey:key];
        } else if ([key hasPrefix:self.overlayAttributePrefix]) {
            NSString *realKey = [key substringFromIndex:self.overlayAttributePrefix.length];
            [ovl setObject:obj forKey:realKey];
        }
    }];
    
    [base addEntriesFromDictionary:ovl];
    return base;
}


- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{
    editInProgress = YES;
    
    [self.parentTextStorage replaceCharactersInRange:range withString:str];
    [self edited:NSTextStorageEditedCharacters range:range changeInLength:str.length-range.length];
    
    editInProgress = NO;
}


- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    editInProgress = YES;
    
    NSMutableDictionary *fixeddict = [NSMutableDictionary dictionary];
    [attrs enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *newkey = [self.overlayAttributePrefix stringByAppendingString:key];
        [fixeddict setObject:obj forKey:newkey];
    }];
    
    [self.parentTextStorage setAttributes:fixeddict range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    
    editInProgress = NO;
}


@end
