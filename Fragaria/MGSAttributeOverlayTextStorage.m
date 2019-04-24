//
//  MGSAttributeOverlayTextStorage.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 28/10/2018.
//

#import "MGSAttributeOverlayTextStorage.h"
#import "MGSRangeEntries.h"


static NSString * const MGSAttributeOverlayPrefixBase = @"__MGSAttributeOverlay_";


@interface MGSAttributeOverlayTextStorage ()

@end


@implementation MGSAttributeOverlayTextStorage
{
    NSInteger editingBlockLevel;
    BOOL parentEditInProgress;
    MGSRangeEntries *attributeRanges;
}


- (instancetype)initWithParentTextStorage:(NSTextStorage *)ts
{
    self = [super init];
    
    _parentTextStorage = ts;
    attributeRanges = MGSCreateRangeToCopiedObjectEntries(0);
    MGSRangeEntryInsert(attributeRanges, NSMakeRange(0, ts.length), @{});
    
    editingBlockLevel = 0;
    parentEditInProgress = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentTextStorageDidProcessEdit:) name:NSTextStorageDidProcessEditingNotification object:ts];
    
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
    MGSFreeRangeEntries(attributeRanges);
}


- (NSString *)string
{
    return self.parentTextStorage.string;
}


- (void)parentTextStorageDidProcessEdit:(NSNotification *)notif
{
    if (editingBlockLevel > 0)
        return;
    
    parentEditInProgress = YES;
    
    NSRange range = self.parentTextStorage.editedRange;
    range.length -= self.parentTextStorage.changeInLength;
    [self edited:self.parentTextStorage.editedMask range:range changeInLength:self.parentTextStorage.changeInLength];
    
    parentEditInProgress = NO;
}


- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    NSRange pRange, myRange;
    NSDictionary *pAttrib = [self.parentTextStorage attributesAtIndex:location effectiveRange:&pRange];
    NSDictionary *myAttrib = MGSRangeEntryAtIndex(attributeRanges, location, &myRange);
    if (!myAttrib) {
        myAttrib = @{};
    }
    if (range) {
        if (myRange.length == NSNotFound)
            myRange.length = self.length - myRange.location;
        *range = NSIntersectionRange(pRange, myRange);
    }
    
    NSMutableDictionary *res = [pAttrib mutableCopy];
    NSSet *removalSet = [myAttrib keysOfEntriesPassingTest:^BOOL(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        return obj == [NSNull null];
    }];
    [res addEntriesFromDictionary:myAttrib];
    [res removeObjectsForKeys:[removalSet allObjects]];
    return res;
}


- (void)beginEditing
{
    editingBlockLevel++;
    [self.parentTextStorage beginEditing];
    [super beginEditing];
}


- (void)endEditing
{
    [self.parentTextStorage endEditing];
    [super endEditing];
    editingBlockLevel = MAX(0, editingBlockLevel - 1);
}


- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{
    [self beginEditing];
    NSInteger delta = str.length - range.length;
    [self.parentTextStorage replaceCharactersInRange:range withString:str];
    MGSRangeEntriesExpandAndWipe(attributeRanges, range, delta);
    if (MGSCountRangeEntries(attributeRanges) == 0)
        MGSRangeEntryInsert(attributeRanges, NSMakeRange(0, self.parentTextStorage.length), @{});
    [self edited:NSTextStorageEditedCharacters range:range changeInLength:str.length-range.length];
    [self endEditing];
}


- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    [self beginEditing];
    
    __block NSMutableDictionary *newAttributes = [NSMutableDictionary dictionary];
    [self.parentTextStorage
        enumerateAttributesInRange:range
        options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
        usingBlock:^(NSDictionary<NSAttributedStringKey, id> * _Nonnull attrs, NSRange subrange, BOOL * _Nonnull stop)
    {
        for (NSString *key in attrs) {
            [newAttributes setObject:[NSNull null] forKey:key];
        }
    }];
    [newAttributes addEntriesFromDictionary:attrs];
    
    if (self.parentTextStorage.length == 0) {
        MGSResetRangeEntries(attributeRanges);
        MGSRangeEntryInsert(attributeRanges, range, newAttributes);
    } else if (range.length > 0) {
        MGSRangeEntriesDivideAndConquer(attributeRanges, range);
        MGSRangeEntryInsert(attributeRanges, range, newAttributes);
    }
    
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}


@end
