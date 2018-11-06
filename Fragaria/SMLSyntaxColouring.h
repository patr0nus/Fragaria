/*
 
 MGSFragaria
 Written by Jonathan Mitchell, jonathan@mugginsoft.com
 Find the latest version at https://github.com/mugginsoft/Fragaria
 
 Smultron version 3.6b1, 2009-09-12
 Written by Peter Borg, pgw3@mac.com
 Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use
 this file except in compliance with the License. You may obtain a copy of the
 License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed
 under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 CONDITIONS OF ANY KIND, either express or implied. See the License for the
 specific language governing permissions and limitations under the License.
*/
/// @cond PRIVATE

#import <Cocoa/Cocoa.h>
#import "MGSSyntaxParserClient.h"


@class SMLLayoutManager;
@class MGSFragariaView;
@class SMLTextView;
@class MGSSyntaxDefinition;
@class MGSColourScheme;

@protocol SMLAutoCompleteDelegate;


/**
 *  Performs syntax colouring on the text editor document.
 **/
@interface SMLSyntaxColouring : NSObject <MGSSyntaxParserClient>


/// @name Properties - Internal

/** The MGSFragaria instance to be passed to the syntax colouring delegate
 * as the fragaria document parameter. */
@property (weak) MGSFragariaView *fragaria;

/** The layout manager of the text view */
@property (readonly, weak) NSLayoutManager *layoutManager;

/** Specifies the current syntax definition name.*/
@property (nonatomic) NSString *syntaxDefinitionName;

/** The syntax definition that determines how to color the text. */
@property (nonatomic, strong) MGSSyntaxDefinition *syntaxDefinition;

/** Indicates the character ranges where colouring is valid. */
@property (strong, readonly) NSMutableIndexSet *inspectedCharacterIndexes;


/// @name Properties - Appearance and Behavior


/** The colour scheme */
@property (nonatomic, strong) MGSColourScheme *colourScheme;

/** If multiline strings should be coloured. */
@property (nonatomic, assign) BOOL coloursMultiLineStrings;
/** If coloring should end at end of line. */
@property (nonatomic, assign) BOOL coloursOnlyUntilEndOfLine;


/// @name Instance Methods


/** Initialize a new instance using the specified layout manager.
 * @param lm The layout manager associated with this instance. */
- (id)initWithLayoutManager:(NSLayoutManager *)lm;

/** Inform this syntax colourer that its layout manager's text storage
 *  will change.
 *  @discussion In response to this message, the syntax colourer view must
 *              remove itself as observer of any notifications from the old
 *              text storage. */
- (void)layoutManagerWillChangeTextStorage;

/** Inform this syntax colourer that its layout manager's text storage
 *  has changed.
 *  @discussion In this method the syntax colourer can register as observer
 *              of any of the new text storage's notifications. */
- (void)layoutManagerDidChangeTextStorage;


/** Recolors the invalid characters in the specified range.
 * @param range A character range where, when this method returns, all syntax
 *              colouring will be guaranteed to be up-to-date. */
- (void)recolourRange:(NSRange)range;

/** Marks as invalid the colouring in the range currently visible (not clipped)
 *  in the specified text view.
 *  @param textView The text view from which to get a character range. */
- (void)invalidateVisibleRangeOfTextView:(SMLTextView *)textView;

/** Marks the entire text's colouring as invalid and removes all coloring
 *  attributes applied. */
- (void)invalidateAllColouring;

/** Forces a recolouring of the character range specified. The recolouring will
 * be done anew even if the specified range is already valid (wholly or in
 * part).
 * @param rangeToRecolour Indicates the range to be recoloured.
 * @return The range that was effectively coloured. The returned range always
 *         contains entirely the initial range. */
- (NSRange)recolourChangedRange:(NSRange)rangeToRecolour;


@end
