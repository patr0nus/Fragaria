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
#import "MGSAbstractSyntaxColouring.h"
#import "MGSSyntaxParserClient.h"


@class MGSLayoutManager;
@class MGSFragariaView;
@class MGSTextView;

@protocol MGSAutoCompleteDelegate;


/**
 *  Performs syntax colouring on the text editor document.
 **/
@interface MGSSyntaxColouring : MGSAbstractSyntaxColouring


/** Initialize a new instance using the specified layout manager.
 * @param lm The layout manager associated with this instance. */
- (id)initWithLayoutManager:(NSLayoutManager *)lm;


/// @name Setting the object of coloring

/** The layout manager of the text view */
@property (readonly, weak) NSLayoutManager *layoutManager;


/// @name Reacting to text changes

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


/// @name Performing Highlighting

/** Marks as invalid the colouring in the range currently visible (not clipped)
 *  in the specified text view.
 *  @param textView The text view from which to get a character range. */
- (void)invalidateVisibleRangeOfTextView:(MGSTextView *)textView;


@end
