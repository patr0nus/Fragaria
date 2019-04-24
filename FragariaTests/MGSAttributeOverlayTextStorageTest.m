//
//  MGSAttributeOverlayTextStorageTest.m
//  Fragaria Tests
//
//  Created by Daniele Cattaneo on 28/10/2018.
//

#import <XCTest/XCTest.h>
#import "MGSAttributeOverlayTextStorage.h"


@interface MGSAttributeOverlayTextStorageTestHelper: NSObject
{
    @public
    NSTextStorageEditActions expected_action;
    NSRange expected_range;
    NSInteger expected_changeInLength;
    NSInteger optionCheck;
    id did_source;
    NSInteger did_count;
    id will_source;
    NSInteger will_count;
}

@end


@implementation MGSAttributeOverlayTextStorageTestHelper


@end


@interface MGSAttributeOverlayTextStorageTestNotificationHelper: MGSAttributeOverlayTextStorageTestHelper

- (void)textStorageDidProcessEditing:(NSNotification *)notification;
- (void)textStorageWillProcessEditing:(NSNotification *)notification;

@end


@implementation MGSAttributeOverlayTextStorageTestNotificationHelper


- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
    optionCheck += [notification.object editedMask] == expected_action &&
        NSEqualRanges([notification.object editedRange], expected_range) &&
        [notification.object changeInLength] == expected_changeInLength;
    did_source = notification.object;
    did_count++;
}


- (void)textStorageWillProcessEditing:(NSNotification *)notification
{
    optionCheck += [notification.object editedMask] == expected_action &&
        NSEqualRanges([notification.object editedRange], expected_range) &&
        [notification.object changeInLength] == expected_changeInLength;
    will_source = notification.object;
    will_count++;
}


@end


@interface MGSAttributeOverlayTextStorageTestDelegateHelper: MGSAttributeOverlayTextStorageTestHelper <NSTextStorageDelegate>

- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta;
- (void)textStorage:(NSTextStorage *)textStorage willProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta;

@end


@implementation MGSAttributeOverlayTextStorageTestDelegateHelper


- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta
{
    optionCheck +=
        [textStorage editedMask] == expected_action &&
        editedMask == expected_action &&
        NSEqualRanges([textStorage editedRange], expected_range) &&
        NSEqualRanges(editedRange, expected_range) &&
        [textStorage changeInLength] == expected_changeInLength &&
        delta == expected_changeInLength;
    did_source = textStorage;
    did_count++;
}


- (void)textStorage:(NSTextStorage *)textStorage willProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta
{
    optionCheck +=
        [textStorage editedMask] == expected_action &&
        editedMask == expected_action &&
        NSEqualRanges([textStorage editedRange], expected_range) &&
        NSEqualRanges(editedRange, expected_range) &&
        [textStorage changeInLength] == expected_changeInLength &&
        delta == expected_changeInLength;
    will_source = textStorage;
    will_count++;
}


@end


@interface MGSAttributeOverlayTextStorageTest : XCTestCase

@end


@implementation MGSAttributeOverlayTextStorageTest


- (void)checkAttributes:(NSDictionary *)attributes inRange:(NSRange)effectiveRange inTextStorage:(NSTextStorage *)textStorage
{
    NSRange wholerange = NSMakeRange(0, textStorage.length);
    NSRange checkrange;
    NSDictionary *realattr = [textStorage attributesAtIndex:effectiveRange.location longestEffectiveRange:&checkrange inRange:wholerange];
    XCTAssertTrue(NSEqualRanges(checkrange, effectiveRange), @"%@ != %@", NSStringFromRange(checkrange), NSStringFromRange(effectiveRange));
    XCTAssertEqualObjects(attributes, realattr);
}


- (void)testCreation
{
    NSTextStorage *test = [[NSTextStorage alloc] initWithString:@"test"];
    MGSAttributeOverlayTextStorage *aots = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:test];
    MGSAttributeOverlayTextStorage *aots2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:test];
    
    XCTAssertTrue([test.string isEqual:aots.string]);
    XCTAssertTrue([test.string isEqual:aots2.string]);
    XCTAssertTrue([aots.string isEqual:aots2.string]);
    
    XCTAssertTrue([test isEqual:aots]);
    XCTAssertTrue([test isEqual:aots2]);
    XCTAssertTrue([aots isEqual:aots2]);
}


- (void)testParentTextModification
{
    NSTextStorage *test = [[NSTextStorage alloc] initWithString:@"test"];
    MGSAttributeOverlayTextStorage *aots = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:test];
    MGSAttributeOverlayTextStorage *aots2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:test];
    
    [test replaceCharactersInRange:NSMakeRange(2, 1) withString:@"(TEST)s"];
    
    XCTAssertTrue([test.string isEqual:@"te(TEST)st"]);
    XCTAssertTrue([aots.string isEqual:@"te(TEST)st"]);
    XCTAssertTrue([aots2.string isEqual:@"te(TEST)st"]);
}


- (void)testChildTextModification
{
    NSDictionary *attr1 = @{NSFontAttributeName: [NSFont fontWithName:@"Times" size:12.0]};
    NSDictionary *attr2 = @{NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:12.0]};
    NSDictionary *attr3 = @{NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:15.0]};
    
    NSTextStorage *test = [[NSTextStorage alloc] initWithString:@"test" attributes:attr1];
    MGSAttributeOverlayTextStorage *aots = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:test];
    MGSAttributeOverlayTextStorage *aots2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:test];
    
    [aots replaceCharactersInRange:NSMakeRange(2, 1) withString:@"(TEST)s"];
    [aots setAttributes:attr2 range:NSMakeRange(2, 6)];
    
    XCTAssertTrue([test.string isEqual:@"te(TEST)st"]);
    XCTAssertTrue([aots.string isEqual:@"te(TEST)st"]);
    XCTAssertTrue([aots2.string isEqual:@"te(TEST)st"]);
    [self checkAttributes:attr1 inRange:NSMakeRange(0, 10) inTextStorage:test];
    [self checkAttributes:attr1 inRange:NSMakeRange(0, 2) inTextStorage:aots];
    [self checkAttributes:attr2 inRange:NSMakeRange(2, 6) inTextStorage:aots];
    [self checkAttributes:attr1 inRange:NSMakeRange(8, 2) inTextStorage:aots];
    [self checkAttributes:attr1 inRange:NSMakeRange(0, 10) inTextStorage:aots2];
    
    [aots2 replaceCharactersInRange:NSMakeRange(1, 0) withString:@"(REPLACED)"];
    [aots2 setAttributes:attr3 range:NSMakeRange(1, 10)];
    
    XCTAssertTrue([test.string isEqual:@"t(REPLACED)e(TEST)st"]);
    XCTAssertTrue([aots.string isEqual:@"t(REPLACED)e(TEST)st"]);
    XCTAssertTrue([aots2.string isEqual:@"t(REPLACED)e(TEST)st"]);
    [self checkAttributes:attr1 inRange:NSMakeRange(0, 10) inTextStorage:test];
    [self checkAttributes:attr1 inRange:NSMakeRange(0, 12) inTextStorage:aots];
    [self checkAttributes:attr2 inRange:NSMakeRange(12, 6) inTextStorage:aots];
    [self checkAttributes:attr1 inRange:NSMakeRange(18, 2) inTextStorage:aots];
    [self checkAttributes:attr1 inRange:NSMakeRange(0, 1) inTextStorage:aots2];
    [self checkAttributes:attr3 inRange:NSMakeRange(1, 10) inTextStorage:aots2];
    [self checkAttributes:attr1 inRange:NSMakeRange(11, 9) inTextStorage:aots2];
}


- (void)testParentAttributesVisibility
{
    NSDictionary *attr1 = @{NSFontAttributeName: [NSFont fontWithName:@"Times" size:12.0]};
    NSDictionary *attr2 = @{NSForegroundColorAttributeName: [NSColor redColor]};
    
    NSTextStorage *test = [[NSTextStorage alloc] initWithString:@"[no attributes][attr1][attr2]"];
    MGSAttributeOverlayTextStorage *aots = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:test];
    MGSAttributeOverlayTextStorage *aots2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:test];
    
    [test setAttributes:attr1 range:NSMakeRange(15, 7)];
    XCTAssertTrue([test isEqual:aots]);
    XCTAssertTrue([test isEqual:aots2]);
    XCTAssertTrue([aots isEqual:aots2]);
    
    NSAttributedString *tmp = [[NSAttributedString alloc] initWithString:@"[ATTR2]" attributes:attr2];
    [test replaceCharactersInRange:NSMakeRange(22, 7) withAttributedString:tmp];
    XCTAssertTrue([test isEqual:aots]);
    XCTAssertTrue([test isEqual:aots2]);
    XCTAssertTrue([aots isEqual:aots2]);
}


- (void)testChildAttributesVisibility
{
    NSDictionary *attr0 = @{NSFontAttributeName: [NSFont userFontOfSize:12.0]};
    NSDictionary *attr1 = @{NSFontAttributeName: [NSFont fontWithName:@"Times" size:12.0]};
    NSDictionary *attr2 = @{NSForegroundColorAttributeName: [NSColor redColor]};
    NSDictionary *attr0u2 = @{NSFontAttributeName: [NSFont userFontOfSize:12.0], NSForegroundColorAttributeName: [NSColor redColor]};
    
    NSTextStorage *parent = [[NSTextStorage alloc] initWithString:@"0123456789" attributes:attr0];
    MGSAttributeOverlayTextStorage *child1 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    MGSAttributeOverlayTextStorage *child2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    
    [child1 setAttributes:attr1 range:NSMakeRange(3, 4)];
    XCTAssertFalse([[parent attributeKeys] containsObject:NSFontAttributeName]);
    [self checkAttributes:attr0 inRange:NSMakeRange(0, 3) inTextStorage:child1];
    [self checkAttributes:attr1 inRange:NSMakeRange(3, 4) inTextStorage:child1];
    [self checkAttributes:attr0 inRange:NSMakeRange(7, 3) inTextStorage:child1];
    [self checkAttributes:attr0 inRange:NSMakeRange(0, 10) inTextStorage:child2];
    
    [child2 setAttributes:attr2 range:NSMakeRange(5, 5)];
    XCTAssertFalse([[parent attributeKeys] containsObject:NSFontAttributeName]);
    XCTAssertFalse([[parent attributeKeys] containsObject:NSForegroundColorAttributeName]);
    [self checkAttributes:attr0 inRange:NSMakeRange(0, 3) inTextStorage:child1];
    [self checkAttributes:attr1 inRange:NSMakeRange(3, 4) inTextStorage:child1];
    [self checkAttributes:attr0 inRange:NSMakeRange(7, 3) inTextStorage:child1];
    [self checkAttributes:attr0 inRange:NSMakeRange(0, 5) inTextStorage:child2];
    [self checkAttributes:attr0u2 inRange:NSMakeRange(5, 5) inTextStorage:child2];
}


- (void)testParentNotificationInChildren
{
    MGSAttributeOverlayTextStorageTestNotificationHelper *parentNotificationState = [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    MGSAttributeOverlayTextStorageTestNotificationHelper *child1NotificationState= [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    MGSAttributeOverlayTextStorageTestNotificationHelper *child2NotificationState= [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    
    NSTextStorage *parent = [[NSTextStorage alloc] initWithString:@"0123456789"];
    MGSAttributeOverlayTextStorage *child1 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    MGSAttributeOverlayTextStorage *child2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    
    [[NSNotificationCenter defaultCenter] addObserver:parentNotificationState selector:@selector(textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:parent];
    [[NSNotificationCenter defaultCenter] addObserver:parentNotificationState selector:@selector(textStorageWillProcessEditing:) name:NSTextStorageWillProcessEditingNotification object:parent];
    
    [[NSNotificationCenter defaultCenter] addObserver:child1NotificationState selector:@selector(textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:child1];
    [[NSNotificationCenter defaultCenter] addObserver:child1NotificationState selector:@selector(textStorageWillProcessEditing:) name:NSTextStorageWillProcessEditingNotification object:child1];
    
    [[NSNotificationCenter defaultCenter] addObserver:child2NotificationState selector:@selector(textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:child2];
    [[NSNotificationCenter defaultCenter] addObserver:child2NotificationState selector:@selector(textStorageWillProcessEditing:) name:NSTextStorageWillProcessEditingNotification object:child2];
    
    parentNotificationState->expected_action = NSTextStorageEditedCharacters;
    child1NotificationState->expected_action = NSTextStorageEditedCharacters;
    child2NotificationState->expected_action = NSTextStorageEditedCharacters;
    parentNotificationState->expected_changeInLength = 1;
    child1NotificationState->expected_changeInLength = 1;
    child2NotificationState->expected_changeInLength = 1;
    parentNotificationState->expected_range = NSMakeRange(3, 3);
    child1NotificationState->expected_range = NSMakeRange(3, 3);
    child2NotificationState->expected_range = NSMakeRange(3, 3);
    
    [parent replaceCharactersInRange:NSMakeRange(3, 2) withString:@"ABC"];
    
    XCTAssertEqual(parentNotificationState->did_source, parent);
    XCTAssertEqual(child1NotificationState->did_source, child1);
    XCTAssertEqual(child2NotificationState->did_source, child2);
    XCTAssertEqual(parentNotificationState->will_source, parent);
    XCTAssertEqual(child1NotificationState->will_source, child1);
    XCTAssertEqual(child2NotificationState->will_source, child2);
    XCTAssertEqual(parentNotificationState->optionCheck, 2);
    XCTAssertEqual(child1NotificationState->optionCheck, 2);
    XCTAssertEqual(child2NotificationState->optionCheck, 2);
    XCTAssertEqual(parentNotificationState->did_count, 1);
    XCTAssertEqual(child1NotificationState->did_count, 1);
    XCTAssertEqual(child2NotificationState->did_count, 1);
    XCTAssertEqual(parentNotificationState->will_count, 1);
    XCTAssertEqual(child1NotificationState->will_count, 1);
    XCTAssertEqual(child2NotificationState->will_count, 1);
}


- (void)testChildNotificationInChildrenAndParent
{
    MGSAttributeOverlayTextStorageTestNotificationHelper *parentNotificationState = [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    MGSAttributeOverlayTextStorageTestNotificationHelper *child1NotificationState= [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    MGSAttributeOverlayTextStorageTestNotificationHelper *child2NotificationState= [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    
    NSTextStorage *parent = [[NSTextStorage alloc] initWithString:@"0123456789"];
    MGSAttributeOverlayTextStorage *child1 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    MGSAttributeOverlayTextStorage *child2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    
    [[NSNotificationCenter defaultCenter] addObserver:parentNotificationState selector:@selector(textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:parent];
    [[NSNotificationCenter defaultCenter] addObserver:parentNotificationState selector:@selector(textStorageWillProcessEditing:) name:NSTextStorageWillProcessEditingNotification object:parent];
    
    [[NSNotificationCenter defaultCenter] addObserver:child1NotificationState selector:@selector(textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:child1];
    [[NSNotificationCenter defaultCenter] addObserver:child1NotificationState selector:@selector(textStorageWillProcessEditing:) name:NSTextStorageWillProcessEditingNotification object:child1];
    
    [[NSNotificationCenter defaultCenter] addObserver:child2NotificationState selector:@selector(textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:child2];
    [[NSNotificationCenter defaultCenter] addObserver:child2NotificationState selector:@selector(textStorageWillProcessEditing:) name:NSTextStorageWillProcessEditingNotification object:child2];
    
    parentNotificationState->expected_action = NSTextStorageEditedCharacters;
    child1NotificationState->expected_action = NSTextStorageEditedCharacters;
    child2NotificationState->expected_action = NSTextStorageEditedCharacters;
    parentNotificationState->expected_changeInLength = 1;
    child1NotificationState->expected_changeInLength = 1;
    child2NotificationState->expected_changeInLength = 1;
    parentNotificationState->expected_range = NSMakeRange(3, 3);
    child1NotificationState->expected_range = NSMakeRange(3, 3);
    child2NotificationState->expected_range = NSMakeRange(3, 3);
    
    [child1 replaceCharactersInRange:NSMakeRange(3, 2) withString:@"ABC"];
    
    XCTAssertEqual(parentNotificationState->did_source, parent);
    XCTAssertEqual(child1NotificationState->did_source, child1);
    XCTAssertEqual(child2NotificationState->did_source, child2);
    XCTAssertEqual(parentNotificationState->will_source, parent);
    XCTAssertEqual(child1NotificationState->will_source, child1);
    XCTAssertEqual(child2NotificationState->will_source, child2);
    XCTAssertEqual(parentNotificationState->optionCheck, 2);
    XCTAssertEqual(child1NotificationState->optionCheck, 2);
    XCTAssertEqual(child2NotificationState->optionCheck, 2);
    XCTAssertEqual(parentNotificationState->did_count, 1);
    XCTAssertEqual(child1NotificationState->did_count, 1);
    XCTAssertEqual(child2NotificationState->did_count, 1);
    XCTAssertEqual(parentNotificationState->will_count, 1);
    XCTAssertEqual(child1NotificationState->will_count, 1);
    XCTAssertEqual(child2NotificationState->will_count, 1);
}


- (void)testParentDelegateInvocationInChildren
{
    MGSAttributeOverlayTextStorageTestDelegateHelper *parentNotificationState = [[MGSAttributeOverlayTextStorageTestDelegateHelper alloc] init];
    MGSAttributeOverlayTextStorageTestDelegateHelper *child1NotificationState= [[MGSAttributeOverlayTextStorageTestDelegateHelper alloc] init];
    MGSAttributeOverlayTextStorageTestDelegateHelper *child2NotificationState= [[MGSAttributeOverlayTextStorageTestDelegateHelper alloc] init];
    
    NSTextStorage *parent = [[NSTextStorage alloc] initWithString:@"0123456789"];
    MGSAttributeOverlayTextStorage *child1 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    MGSAttributeOverlayTextStorage *child2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    
    parent.delegate = parentNotificationState;
    child1.delegate = child1NotificationState;
    child2.delegate = child2NotificationState;
    
    parentNotificationState->expected_action = NSTextStorageEditedCharacters;
    child1NotificationState->expected_action = NSTextStorageEditedCharacters;
    child2NotificationState->expected_action = NSTextStorageEditedCharacters;
    parentNotificationState->expected_changeInLength = 1;
    child1NotificationState->expected_changeInLength = 1;
    child2NotificationState->expected_changeInLength = 1;
    parentNotificationState->expected_range = NSMakeRange(3, 3);
    child1NotificationState->expected_range = NSMakeRange(3, 3);
    child2NotificationState->expected_range = NSMakeRange(3, 3);
    
    [parent replaceCharactersInRange:NSMakeRange(3, 2) withString:@"ABC"];
    
    XCTAssertEqual(parentNotificationState->did_source, parent);
    XCTAssertEqual(child1NotificationState->did_source, child1);
    XCTAssertEqual(child2NotificationState->did_source, child2);
    XCTAssertEqual(parentNotificationState->will_source, parent);
    XCTAssertEqual(child1NotificationState->will_source, child1);
    XCTAssertEqual(child2NotificationState->will_source, child2);
    XCTAssertEqual(parentNotificationState->optionCheck, 2);
    XCTAssertEqual(child1NotificationState->optionCheck, 2);
    XCTAssertEqual(child2NotificationState->optionCheck, 2);
    XCTAssertEqual(parentNotificationState->did_count, 1);
    XCTAssertEqual(child1NotificationState->did_count, 1);
    XCTAssertEqual(child2NotificationState->did_count, 1);
    XCTAssertEqual(parentNotificationState->will_count, 1);
    XCTAssertEqual(child1NotificationState->will_count, 1);
    XCTAssertEqual(child2NotificationState->will_count, 1);
}


- (void)testChildDelegateInvocationInChildrenAndParent
{
    MGSAttributeOverlayTextStorageTestDelegateHelper *parentNotificationState = [[MGSAttributeOverlayTextStorageTestDelegateHelper alloc] init];
    MGSAttributeOverlayTextStorageTestDelegateHelper *child1NotificationState= [[MGSAttributeOverlayTextStorageTestDelegateHelper alloc] init];
    MGSAttributeOverlayTextStorageTestDelegateHelper *child2NotificationState= [[MGSAttributeOverlayTextStorageTestDelegateHelper alloc] init];
    
    NSTextStorage *parent = [[NSTextStorage alloc] initWithString:@"0123456789"];
    MGSAttributeOverlayTextStorage *child1 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    MGSAttributeOverlayTextStorage *child2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    
    parent.delegate = parentNotificationState;
    child1.delegate = child1NotificationState;
    child2.delegate = child2NotificationState;
    
    parentNotificationState->expected_action = NSTextStorageEditedCharacters;
    child1NotificationState->expected_action = NSTextStorageEditedCharacters;
    child2NotificationState->expected_action = NSTextStorageEditedCharacters;
    parentNotificationState->expected_changeInLength = 1;
    child1NotificationState->expected_changeInLength = 1;
    child2NotificationState->expected_changeInLength = 1;
    parentNotificationState->expected_range = NSMakeRange(3, 3);
    child1NotificationState->expected_range = NSMakeRange(3, 3);
    child2NotificationState->expected_range = NSMakeRange(3, 3);
    
    [child1 replaceCharactersInRange:NSMakeRange(3, 2) withString:@"ABC"];
    
    XCTAssertEqual(parentNotificationState->did_source, parent);
    XCTAssertEqual(child1NotificationState->did_source, child1);
    XCTAssertEqual(child2NotificationState->did_source, child2);
    XCTAssertEqual(parentNotificationState->will_source, parent);
    XCTAssertEqual(child1NotificationState->will_source, child1);
    XCTAssertEqual(child2NotificationState->will_source, child2);
    XCTAssertEqual(parentNotificationState->optionCheck, 2);
    XCTAssertEqual(child1NotificationState->optionCheck, 2);
    XCTAssertEqual(child2NotificationState->optionCheck, 2);
    XCTAssertEqual(parentNotificationState->did_count, 1);
    XCTAssertEqual(child1NotificationState->did_count, 1);
    XCTAssertEqual(child2NotificationState->did_count, 1);
    XCTAssertEqual(parentNotificationState->will_count, 1);
    XCTAssertEqual(child1NotificationState->will_count, 1);
    XCTAssertEqual(child2NotificationState->will_count, 1);
}


- (void)testParentOldStyleDelegateInvocationInChildren
{
    MGSAttributeOverlayTextStorageTestNotificationHelper *parentNotificationState = [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    MGSAttributeOverlayTextStorageTestNotificationHelper *child1NotificationState= [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    MGSAttributeOverlayTextStorageTestNotificationHelper *child2NotificationState= [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    
    NSTextStorage *parent = [[NSTextStorage alloc] initWithString:@"0123456789"];
    MGSAttributeOverlayTextStorage *child1 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    MGSAttributeOverlayTextStorage *child2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    
    parent.delegate = (id<NSTextStorageDelegate>)parentNotificationState;
    child1.delegate = (id<NSTextStorageDelegate>)child1NotificationState;
    child2.delegate = (id<NSTextStorageDelegate>)child2NotificationState;
    
    parentNotificationState->expected_action = NSTextStorageEditedCharacters;
    child1NotificationState->expected_action = NSTextStorageEditedCharacters;
    child2NotificationState->expected_action = NSTextStorageEditedCharacters;
    parentNotificationState->expected_changeInLength = 1;
    child1NotificationState->expected_changeInLength = 1;
    child2NotificationState->expected_changeInLength = 1;
    parentNotificationState->expected_range = NSMakeRange(3, 3);
    child1NotificationState->expected_range = NSMakeRange(3, 3);
    child2NotificationState->expected_range = NSMakeRange(3, 3);
    
    [parent replaceCharactersInRange:NSMakeRange(3, 2) withString:@"ABC"];
    
    XCTAssertEqual(parentNotificationState->did_source, parent);
    XCTAssertEqual(child1NotificationState->did_source, child1);
    XCTAssertEqual(child2NotificationState->did_source, child2);
    XCTAssertEqual(parentNotificationState->will_source, parent);
    XCTAssertEqual(child1NotificationState->will_source, child1);
    XCTAssertEqual(child2NotificationState->will_source, child2);
    XCTAssertEqual(parentNotificationState->optionCheck, 2);
    XCTAssertEqual(child1NotificationState->optionCheck, 2);
    XCTAssertEqual(child2NotificationState->optionCheck, 2);
    XCTAssertEqual(parentNotificationState->did_count, 1);
    XCTAssertEqual(child1NotificationState->did_count, 1);
    XCTAssertEqual(child2NotificationState->did_count, 1);
    XCTAssertEqual(parentNotificationState->will_count, 1);
    XCTAssertEqual(child1NotificationState->will_count, 1);
    XCTAssertEqual(child2NotificationState->will_count, 1);
}


- (void)testChildOldStyleDelegateInvocationInChildrenAndParent
{
    MGSAttributeOverlayTextStorageTestNotificationHelper *parentNotificationState = [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    MGSAttributeOverlayTextStorageTestNotificationHelper *child1NotificationState= [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    MGSAttributeOverlayTextStorageTestNotificationHelper *child2NotificationState= [[MGSAttributeOverlayTextStorageTestNotificationHelper alloc] init];
    
    NSTextStorage *parent = [[NSTextStorage alloc] initWithString:@"0123456789"];
    MGSAttributeOverlayTextStorage *child1 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    MGSAttributeOverlayTextStorage *child2 = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:parent];
    
    parent.delegate = (id<NSTextStorageDelegate>)parentNotificationState;
    child1.delegate = (id<NSTextStorageDelegate>)child1NotificationState;
    child2.delegate = (id<NSTextStorageDelegate>)child2NotificationState;
    
    parentNotificationState->expected_action = NSTextStorageEditedCharacters;
    child1NotificationState->expected_action = NSTextStorageEditedCharacters;
    child2NotificationState->expected_action = NSTextStorageEditedCharacters;
    parentNotificationState->expected_changeInLength = 1;
    child1NotificationState->expected_changeInLength = 1;
    child2NotificationState->expected_changeInLength = 1;
    parentNotificationState->expected_range = NSMakeRange(3, 3);
    child1NotificationState->expected_range = NSMakeRange(3, 3);
    child2NotificationState->expected_range = NSMakeRange(3, 3);
    
    [child1 replaceCharactersInRange:NSMakeRange(3, 2) withString:@"ABC"];
    
    XCTAssertEqual(parentNotificationState->did_source, parent);
    XCTAssertEqual(child1NotificationState->did_source, child1);
    XCTAssertEqual(child2NotificationState->did_source, child2);
    XCTAssertEqual(parentNotificationState->will_source, parent);
    XCTAssertEqual(child1NotificationState->will_source, child1);
    XCTAssertEqual(child2NotificationState->will_source, child2);
    XCTAssertEqual(parentNotificationState->optionCheck, 2);
    XCTAssertEqual(child1NotificationState->optionCheck, 2);
    XCTAssertEqual(child2NotificationState->optionCheck, 2);
    XCTAssertEqual(parentNotificationState->did_count, 1);
    XCTAssertEqual(child1NotificationState->did_count, 1);
    XCTAssertEqual(child2NotificationState->did_count, 1);
    XCTAssertEqual(parentNotificationState->will_count, 1);
    XCTAssertEqual(child1NotificationState->will_count, 1);
    XCTAssertEqual(child2NotificationState->will_count, 1);
}


@end
