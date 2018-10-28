//
//  MGSFragariaView.m
//  Fragaria
//
//  File created by Jim Derry on 2015/02/07.
//
//  Implements an NSView subclass that abstracts several characteristics of Fragaria,
//  such as the use of Interface Builder to set delegates and assign key-value pairs.
//  Also provides property abstractions for Fragaria's settings and methods.
//

#define FRAGARIA_PRIVATE
#import "NSObject+Fragaria.h"
#import "MGSFragariaView.h"
#import "MGSFragariaViewPrivate.h"
#import "SMLLayoutManager.h"
#import "SMLSyntaxColouring.h"
#import "MGSExtraInterfaceController.h"
#import "MGSLineNumberView.h"
#import "MGSSyntaxController.h"
#import "NSTextStorage+Fragaria.h"
#import "NSString+Fragaria.h"
#import "MGSMutableColourScheme.h"

#import "MGSSyntaxErrorController.h"
#import "SMLSyntaxError.h"

#import "SMLTextView.h"
#import "SMLTextViewPrivate.h"
#import "SMLTextView+MGSTextActions.h"

#import "MGSAttributeOverlayTextStorage.h"


#pragma mark - IMPLEMENTATION


@implementation MGSFragariaView
{
    MGSMutableColourScheme *_colourScheme;
    NSTextStorage *_backingTextStorage;
}

/* Synthesis required in order to implement protocol declarations. */
@synthesize gutterView = _gutterView;
@synthesize scrollView = _scrollView;
@synthesize textView = _textView;
 

#pragma mark - Initialization and Setup


/*
 * - initWithCoder:
 *   Called when unarchived from a nib.
 */
- (instancetype)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder]))
	{
		/*
		   Don't initialize in awakeFromNib otherwise IB User
		   Define Runtime Attributes won't be honored.
		 */
		[self setupView];
	}
	return self;
}


/*
 * - initWithFrame:
 *   Called when used in a framework.
 */
- (instancetype)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]))
    {
		/*
		   Don't initialize in awakeFromNib otherwise IB User
		   Define Runtime Attributes won't be honored.
		 */
		[self setupView];
    }
    return self;
}


/*
 * When using mgs_propagateValue:forBinding we can help ensure type safety by using
 * NSStringFromSelector(@selector(string))] instead of passing a string.
 */


#pragma mark - Accessing Fragaria's Views
/*
 * @property syntaxColouring
 */
- (SMLSyntaxColouring *)syntaxColouring
{
	return self.textView.syntaxColouring;
}


#pragma mark - Accessing Text Content


/*
 * @property string
 */
- (void)setString:(NSString *)string
{
    self.textView.string = string ?: @"";
    [self mgs_propagateValue:string forBinding:NSStringFromSelector(@selector(string))];
}

- (NSString *)string
{
	return self.textView.string;
}


- (NSTextStorage *)textStorage
{
    return _backingTextStorage;
}


/*
 * @property attributedStringWithSyntaxColouring
 */
- (NSAttributedString *)attributedStringWithSyntaxColouring
{
    return self.textView.attributedStringWithSyntaxColouring;
}


#pragma mark - Creating Split Panels


/*
 * - replaceTextStorage:
 */
- (void)replaceTextStorage:(NSTextStorage *)textStorage
{
    NSDictionary *attr;
    
    [self.gutterView layoutManagerWillChangeTextStorage];
    [self.syntaxErrorController layoutManagerWillChangeTextStorage];
    [self.textView.syntaxColouring layoutManagerWillChangeTextStorage];
    
    attr = [self.textView typingAttributes];
    
    _backingTextStorage = textStorage;
    MGSAttributeOverlayTextStorage *realTS = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:_backingTextStorage];
    [realTS setAttributes:attr range:NSMakeRange(0, realTS.length)];
    [self.textView.layoutManager replaceTextStorage:realTS];
    
    [self.gutterView layoutManagerDidChangeTextStorage];
    [self.syntaxErrorController layoutManagerDidChangeTextStorage];
    [self.textView.syntaxColouring layoutManagerDidChangeTextStorage];
}


#pragma mark - Getting Line and Column Information


- (void)getRow:(NSUInteger *)r column:(NSUInteger *)c forCharacterIndex:(NSUInteger)i
{
    [self.textView getRow:r column:c forCharacterIndex:i];
}


- (void)getRow:(NSUInteger *)r indexInRow:(NSUInteger *)c forCharacterIndex:(NSUInteger)i
{
    [self.textView getRow:r indexInRow:c forCharacterIndex:i];
}


- (NSUInteger)characterIndexAtColumn:(NSUInteger)c withinRow:(NSUInteger)r
{
    return [self.textView characterIndexAtColumn:c withinRow:r];
}


- (NSUInteger)characterIndexAtIndex:(NSUInteger)c withinRow:(NSUInteger)r
{
    return [self.textView characterIndexAtIndex:c withinRow:r];
}


#pragma mark - Configuring Syntax Highlighting


/*
 * @property syntaxColoured
 */
- (void)setSyntaxColoured:(BOOL)syntaxColoured
{
	self.textView.syntaxColoured = syntaxColoured;
	[self mgs_propagateValue:@(syntaxColoured) forBinding:NSStringFromSelector(@selector(isSyntaxColoured))];
}

- (BOOL)isSyntaxColoured
{
	return self.textView.isSyntaxColoured;
}


/*
 * @property syntaxDefinitionName
 */
- (void)setSyntaxDefinitionName:(NSString *)syntaxDefinitionName
{
	self.textView.syntaxColouring.syntaxDefinitionName = syntaxDefinitionName;
	[self mgs_propagateValue:syntaxDefinitionName forBinding:NSStringFromSelector(@selector(syntaxDefinitionName))];
}

- (NSString *)syntaxDefinitionName
{
	return self.textView.syntaxColouring.syntaxDefinitionName;
}


/*
 * @property syntaxColouringDelegate
 */
- (void)setSyntaxColouringDelegate:(id<SMLSyntaxColouringDelegate>)syntaxColouringDelegate
{
    self.textView.syntaxColouring.syntaxColouringDelegate = syntaxColouringDelegate;
}

- (id<SMLSyntaxColouringDelegate>)syntaxColoringDelegate
{
    return self.textView.syntaxColouring.syntaxColouringDelegate;
}


/*
 * @property BOOL coloursMultiLineStrings
 */
- (void)setColoursMultiLineStrings:(BOOL)coloursMultiLineStrings
{
    self.textView.syntaxColouring.coloursMultiLineStrings = coloursMultiLineStrings;
	[self mgs_propagateValue:@(coloursMultiLineStrings) forBinding:NSStringFromSelector(@selector(coloursMultiLineStrings))];
}

- (BOOL)coloursMultiLineStrings
{
    return self.textView.syntaxColouring.coloursMultiLineStrings;
}


/*
 * @property BOOL coloursOnlyUntilEndOfLine
 */
- (void)setColoursOnlyUntilEndOfLine:(BOOL)coloursOnlyUntilEndOfLine
{
    self.textView.syntaxColouring.coloursOnlyUntilEndOfLine = coloursOnlyUntilEndOfLine;
	[self mgs_propagateValue:@(coloursOnlyUntilEndOfLine) forBinding:NSStringFromSelector(@selector(coloursOnlyUntilEndOfLine))];
}

- (BOOL)coloursOnlyUntilEndOfLine
{
    return self.textView.syntaxColouring.coloursOnlyUntilEndOfLine;
}


- (void)setColoursFromScheme:(MGSColourScheme *)scheme
{
    NSArray *keys = [MGSColourScheme propertiesOfScheme];
    NSDictionary *colors = [scheme dictionaryWithValuesForKeys:keys];
    [self setValuesForKeysWithDictionary:colors];
}


#pragma mark - Configuring Autocompletion


/*
 * @property autoCompleteDelegate
 */
- (void)setAutoCompleteDelegate:(id<SMLAutoCompleteDelegate>)autoCompleteDelegate
{
    self.textView.autoCompleteDelegate = autoCompleteDelegate;
}

- (id<SMLAutoCompleteDelegate>)autoCompleteDelegate
{
    return self.textView.autoCompleteDelegate;
}


/*
 * @property double autoCompleteDelay
 */
- (void)setAutoCompleteDelay:(double)autoCompleteDelay
{
    self.textView.autoCompleteDelay = autoCompleteDelay;
	[self mgs_propagateValue:@(autoCompleteDelay) forBinding:NSStringFromSelector(@selector(autoCompleteDelay))];
}

- (double)autoCompleteDelay
{
    return self.textView.autoCompleteDelay;
}

 
/*
 * @property BOOL autoCompleteEnabled
 */
- (void)setAutoCompleteEnabled:(BOOL)autoCompleteEnabled
{
    self.textView.autoCompleteEnabled = autoCompleteEnabled;
	[self mgs_propagateValue:@(autoCompleteEnabled) forBinding:NSStringFromSelector(@selector(autoCompleteEnabled))];
}

- (BOOL)autoCompleteEnabled
{
    return self.textView.autoCompleteEnabled;
}

 
/*
 * @property BOOL autoCompleteWithKeywords
 */
- (void)setAutoCompleteWithKeywords:(BOOL)autoCompleteWithKeywords
{
    self.textView.autoCompleteWithKeywords = autoCompleteWithKeywords;
	[self mgs_propagateValue:@(autoCompleteWithKeywords) forBinding:NSStringFromSelector(@selector(autoCompleteWithKeywords))];
}

- (BOOL)autoCompleteWithKeywords
{
    return self.textView.autoCompleteWithKeywords;
}


- (void)setAutoCompleteDisablePreview:(BOOL)autoCompleteDisablePreview
{
    self.textView.autoCompleteDisablePreview = autoCompleteDisablePreview;
}

- (BOOL)autoCompleteDisablePreview
{
    return self.textView.autoCompleteDisablePreview;
}


- (void)setAutoCompleteDisableSpaceEnter:(BOOL)autoCompleteDisableSpaceEnter
{
    self.textView.autoCompleteDisableSpaceEnter = autoCompleteDisableSpaceEnter;
}

- (BOOL)autoCompleteDisableSpaceEnter
{
    return self.textView.autoCompleteDisableSpaceEnter;
}


#pragma mark - Highlighting the current line


/*
 * @property highlightsCurrentLine
 */
- (void)setHighlightsCurrentLine:(BOOL)highlightsCurrentLine
{
    self.textView.highlightsCurrentLine = highlightsCurrentLine;
	[self mgs_propagateValue:@(highlightsCurrentLine) forBinding:NSStringFromSelector(@selector(highlightsCurrentLine))];
}

- (BOOL)highlightsCurrentLine
{
    return self.textView.highlightsCurrentLine;
}


#pragma mark - Configuring the Gutter


/*
 * @property showsGutter
 */
- (void)setShowsGutter:(BOOL)showsGutter
{
	self.scrollView.rulersVisible = showsGutter;
	[self mgs_propagateValue:@(showsGutter) forBinding:NSStringFromSelector(@selector(showsGutter))];
}

- (BOOL)showsGutter
{
	return self.scrollView.rulersVisible;
}


/*
 * @property minimumGutterWidth
 */
- (void)setMinimumGutterWidth:(CGFloat)minimumGutterWidth
{
	self.gutterView.minimumWidth = minimumGutterWidth;
	[self mgs_propagateValue:@(minimumGutterWidth) forBinding:NSStringFromSelector(@selector(minimumGutterWidth))];
}

- (CGFloat)minimumGutterWidth
{
	return self.gutterView.minimumWidth;
}


/*
 * @property showsLineNumbers
 */
- (void)setShowsLineNumbers:(BOOL)showsLineNumbers
{
	self.gutterView.showsLineNumbers = showsLineNumbers;
	[self mgs_propagateValue:@(showsLineNumbers) forBinding:NSStringFromSelector(@selector(showsLineNumbers))];
}

- (BOOL)showsLineNumbers
{
	return self.gutterView.showsLineNumbers;
}


/*
 * @property startingLineNumber
 */
- (void)setStartingLineNumber:(NSUInteger)startingLineNumber
{
	[self.gutterView setStartingLineNumber:startingLineNumber];
	[self mgs_propagateValue:@(startingLineNumber) forBinding:NSStringFromSelector(@selector(startingLineNumber))];
}

- (NSUInteger)startingLineNumber
{
	return [self.gutterView startingLineNumber];
}


/*
 * @property gutterFont
 */
- (void)setGutterFont:(NSFont *)gutterFont
{
    [self.gutterView setFont:gutterFont];
	[self mgs_propagateValue:gutterFont forBinding:NSStringFromSelector(@selector(gutterFont))];
}

- (NSFont *)gutterFont
{
    return self.gutterView.font;
}

/*
 * @property gutterTextColour
 */
- (void)setGutterTextColour:(NSColor *)gutterTextColour
{
    self.gutterView.textColor = gutterTextColour;
	[self mgs_propagateValue:gutterTextColour forBinding:NSStringFromSelector(@selector(gutterTextColour))];
}

- (NSColor *)gutterTextColour
{
    return self.gutterView.textColor;
}

/*
 * @property gutterBackgroundColour
 */
- (void)setGutterBackgroundColour:(NSColor *)gutterBackgroundColour
{
    self.gutterView.backgroundColor = gutterBackgroundColour;
    [self mgs_propagateValue:gutterBackgroundColour forBinding:NSStringFromSelector(@selector(gutterBackgroundColour))];
}

- (NSColor *)gutterBackgroundColour
{
    return self.gutterView.backgroundColor;
}


#pragma mark - Showing Syntax Errors


/*
 * @property syntaxErrors
 */
- (void)setSyntaxErrors:(NSArray *)syntaxErrors
{
	self.syntaxErrorController.syntaxErrors = syntaxErrors;
}

- (NSArray *)syntaxErrors
{
	return self.syntaxErrorController.syntaxErrors;
}


/*
 * @property showsSyntaxErrors
 */
- (void)setShowsSyntaxErrors:(BOOL)showsSyntaxErrors
{
	self.syntaxErrorController.showsSyntaxErrors = showsSyntaxErrors;
	[self mgs_propagateValue:@(showsSyntaxErrors) forBinding:NSStringFromSelector(@selector(showsSyntaxErrors))];
}

- (BOOL)showsSyntaxErrors
{
	return self.syntaxErrorController.showsSyntaxErrors;
}


/*
 * @propertyShowsIndividualErrors
 */
- (void)setShowsIndividualErrors:(BOOL)showsIndividualErrors
{
	self.syntaxErrorController.showsIndividualErrors = showsIndividualErrors;
	[self mgs_propagateValue:@(showsIndividualErrors) forBinding:NSStringFromSelector(@selector(showsIndividualErrors))];
}

- (BOOL)showsIndividualErrors
{
	return self.syntaxErrorController.showsIndividualErrors;
}


#pragma mark - Showing Breakpoints


/*
 * @property breakpointDelegate
 */
- (void)setBreakpointDelegate:(id<MGSBreakpointDelegate>)breakpointDelegate
{
	self.gutterView.breakpointDelegate = breakpointDelegate;
}

- (id<MGSBreakpointDelegate>)breakpointDelegate
{
	return self.gutterView.breakpointDelegate;
}


- (void)reloadBreakpointData
{
    [self.gutterView reloadBreakpointData];
}


#pragma mark - Tabulation and Indentation


/*
 * @property tabWidth
 */
- (void)setTabWidth:(NSInteger)tabWidth
{
    self.textView.tabWidth = tabWidth;
	[self mgs_propagateValue:@(tabWidth) forBinding:NSStringFromSelector(@selector(tabWidth))];
}

- (NSInteger)tabWidth
{
    return self.textView.tabWidth;
}


/*
 * @property indentWidth
 */
- (void)setIndentWidth:(NSUInteger)indentWidth
{
    self.textView.indentWidth = indentWidth;
	[self mgs_propagateValue:@(indentWidth) forBinding:NSStringFromSelector(@selector(indentWidth))];
}

- (NSUInteger)indentWidth
{
    return self.textView.indentWidth;
}


/*
 * @property indentWithSpaces
 */
- (void)setIndentWithSpaces:(BOOL)indentWithSpaces
{
    self.textView.indentWithSpaces = indentWithSpaces;
	[self mgs_propagateValue:@(indentWithSpaces) forBinding:NSStringFromSelector(@selector(indentWithSpaces))];
}

- (BOOL)indentWithSpaces
{
    return self.textView.indentWithSpaces;
}


/*
 * @property useTabStops
 */
- (void)setUseTabStops:(BOOL)useTabStops
{
    self.textView.useTabStops = useTabStops;
	[self mgs_propagateValue:@(useTabStops) forBinding:NSStringFromSelector(@selector(useTabStops))];
}

- (BOOL)useTabStops
{
    return self.textView.useTabStops;
}


/*
 * @property indentBracesAutomatically
 */
- (void)setIndentBracesAutomatically:(BOOL)indentBracesAutomatically
{
    self.textView.indentBracesAutomatically = indentBracesAutomatically;
	[self mgs_propagateValue:@(indentBracesAutomatically) forBinding:NSStringFromSelector(@selector(indentBracesAutomatically))];
}

- (BOOL)indentBracesAutomatically
{
    return self.textView.indentBracesAutomatically;
}


/*
 * @property indentNewLinesAutomatically
 */
- (void)setIndentNewLinesAutomatically:(BOOL)indentNewLinesAutomatically
{
    self.textView.indentNewLinesAutomatically = indentNewLinesAutomatically;
	[self mgs_propagateValue:@(indentNewLinesAutomatically) forBinding:NSStringFromSelector(@selector(indentNewLinesAutomatically))];
}

- (BOOL)indentNewLinesAutomatically
{
    return self.textView.indentNewLinesAutomatically;
}


#pragma mark - Automatic Bracing


/*
 * @property insertClosingParenthesisAutomatically
 */
- (void)setInsertClosingParenthesisAutomatically:(BOOL)insertClosingParenthesisAutomatically
{
    self.textView.insertClosingParenthesisAutomatically = insertClosingParenthesisAutomatically;
	[self mgs_propagateValue:@(insertClosingParenthesisAutomatically) forBinding:NSStringFromSelector(@selector(insertClosingParenthesisAutomatically))];
}

- (BOOL)insertClosingParenthesisAutomatically
{
    return self.textView.insertClosingParenthesisAutomatically;
}


/*
 * @property insertClosingBraceAutomatically
 */
- (void)setInsertClosingBraceAutomatically:(BOOL)insertClosingBraceAutomatically
{
    self.textView.insertClosingBraceAutomatically = insertClosingBraceAutomatically;
	[self mgs_propagateValue:@(insertClosingBraceAutomatically) forBinding:NSStringFromSelector(@selector(insertClosingBraceAutomatically))];
}

- (BOOL)insertClosingBraceAutomatically
{
    return self.textView.insertClosingBraceAutomatically;
}


/*
 * @property showsMatchingBraces
 */
- (void)setShowsMatchingBraces:(BOOL)showsMatchingBraces
{
    self.textView.showsMatchingBraces = showsMatchingBraces;
	[self mgs_propagateValue:@(showsMatchingBraces) forBinding:NSStringFromSelector(@selector(showsMatchingBraces))];
}

- (BOOL)showsMatchingBraces
{
    return self.textView.showsMatchingBraces;
}


#pragma mark - Page Guide and Line Wrap


/*
 * @property pageGuideColumn
 */
- (void)setPageGuideColumn:(NSInteger)pageGuideColumn
{
    self.textView.pageGuideColumn = pageGuideColumn;
	[self mgs_propagateValue:@(pageGuideColumn) forBinding:NSStringFromSelector(@selector(pageGuideColumn))];
}

- (NSInteger)pageGuideColumn
{
    return self.textView.pageGuideColumn;
}


/*
 * @property showsPageGuide
 */
-(void)setShowsPageGuide:(BOOL)showsPageGuide
{
    self.textView.showsPageGuide = showsPageGuide;
	[self mgs_propagateValue:@(showsPageGuide) forBinding:NSStringFromSelector(@selector(showsPageGuide))];
}

- (BOOL)showsPageGuide
{
    return self.textView.showsPageGuide;
}


/*
 * @property lineWrap
 */
- (void)setLineWrap:(BOOL)lineWrap
{
	self.textView.lineWrap = lineWrap;
	[self mgs_propagateValue:@(lineWrap) forBinding:NSStringFromSelector(@selector(lineWrap))];
}

- (BOOL)lineWrap
{
	return self.textView.lineWrap;
}


/*
 * @property lineWrapsAtPageGuide
 */
- (void)setLineWrapsAtPageGuide:(BOOL)lineWrapsAtPageGuide
{
    self.textView.lineWrapsAtPageGuide = lineWrapsAtPageGuide;
    [self mgs_propagateValue:@(lineWrapsAtPageGuide) forBinding:NSStringFromSelector(@selector(lineWrapsAtPageGuide))];
}

- (BOOL)lineWrapsAtPageGuide
{
    return self.textView.lineWrapsAtPageGuide;
}

#pragma mark - Showing Invisible Characters


/*
 * @property showsInvisibleCharacters
 */
- (void)setShowsInvisibleCharacters:(BOOL)showsInvisibleCharacters
{
    self.textView.showsInvisibleCharacters = showsInvisibleCharacters;
	[self mgs_propagateValue:@(showsInvisibleCharacters) forBinding:NSStringFromSelector(@selector(showsInvisibleCharacters))];
}

- (BOOL)showsInvisibleCharacters
{
    return self.textView.showsInvisibleCharacters;
}


- (void)clearInvisibleCharacterSubstitutes
{
    [self.textView clearInvisibleCharacterSubstitutes];
}

- (void)removeSubstituteForInvisibleCharacter:(unichar)character
{
    [self.textView removeSubstituteForInvisibleCharacter:character];
}

- (void)addSubstitute:(NSString * _Nonnull)substitute forInvisibleCharacter:(unichar)character
{
    [self.textView addSubstitute:substitute forInvisibleCharacter:character];
}

#pragma mark - Configuring Text Appearance and Color Schemes


/*
 * @property textFont
 */
- (void)setTextFont:(NSFont *)textFont
{
    self.textView.textFont = textFont;
    [self mgs_propagateValue:textFont forBinding:NSStringFromSelector(@selector(textFont))];
}

- (NSFont *)textFont
{
    return self.textView.textFont;
}


/*
 * @property lineHeightMultiple
 */
- (void)setLineHeightMultiple:(CGFloat)lineHeightMultiple
{
    self.textView.lineHeightMultiple = lineHeightMultiple;
    [self mgs_propagateValue:@(lineHeightMultiple) forBinding:NSStringFromSelector(@selector(lineHeightMultiple))];
}

- (CGFloat)lineHeightMultiple
{
    return self.textView.lineHeightMultiple;
}


- (void)setColourScheme:(MGSColourScheme *)colourScheme
{
    if (colourScheme)
        _colourScheme = [colourScheme mutableCopy];
    else
        _colourScheme = [[MGSMutableColourScheme alloc] init];
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:_colourScheme forBinding:NSStringFromSelector(@selector(colourScheme))];
}

- (MGSColourScheme *)colourScheme
{
    return _colourScheme;
}


- (void)colourSchemeHasChanged
{
    self.textView.colourScheme = _colourScheme;
    self.textView.syntaxColouring.colourScheme = [_colourScheme copy];
    self.syntaxErrorController.defaultSyntaxErrorHighlightingColour = _colourScheme.defaultSyntaxErrorHighlightingColour;
}


#pragma mark - Configuring Additional Text View Behavior


/*
 * @property textViewDelegate
 */
- (void)setTextViewDelegate:(id<MGSFragariaTextViewDelegate, MGSDragOperationDelegate>)textViewDelegate
{
	self.textView.delegate = textViewDelegate;
}

- (id<MGSFragariaTextViewDelegate, MGSDragOperationDelegate>)textViewDelegate
{
	return self.textView.delegate;
}


/*
 * @property hasVerticalScroller
 */
- (void)setHasVerticalScroller:(BOOL)hasVerticalScroller
{
	self.scrollView.hasVerticalScroller = hasVerticalScroller;
	[self mgs_propagateValue:@(hasVerticalScroller) forBinding:NSStringFromSelector(@selector(hasVerticalScroller))];
}

- (BOOL)hasVerticalScroller
{
	return self.scrollView.hasVerticalScroller;
}


/*
 * @property scrollElasticityDisabled
 */
- (void)setScrollElasticityDisabled:(BOOL)scrollElasticityDisabled
{
	NSScrollElasticity setting = scrollElasticityDisabled ? NSScrollElasticityNone : NSScrollElasticityAutomatic;
	self.scrollView.verticalScrollElasticity = setting;
	[self mgs_propagateValue:@(scrollElasticityDisabled) forBinding:NSStringFromSelector(@selector(scrollElasticityDisabled))];
}

- (BOOL)scrollElasticityDisabled
{
	return (self.scrollView.verticalScrollElasticity == NSScrollElasticityNone);
}


/*
 * - goToLine:centered:highlight
 */
- (void)goToLine:(NSInteger)lineToGoTo centered:(BOOL)centered highlight:(BOOL)highlight
{
	if (centered)
		NSLog(@"Warning: centered option is ignored.");
	[self.textView performGoToLine:lineToGoTo setSelected:highlight];
}


#pragma mark - Private/Other/Support

/*
 * - setupView:
 */
- (void)setupView
{
	// create text scrollview
	_scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, [self bounds].size.width, [self bounds].size.height)];
	NSSize contentSize = [self.scrollView contentSize];
	[self.scrollView setBorderType:NSNoBorder];
	
	[self.scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[[self.scrollView contentView] setAutoresizesSubviews:YES];
	[self.scrollView setPostsFrameChangedNotifications:YES];
	self.hasVerticalScroller = YES;
 
     _backingTextStorage = [[NSTextStorage alloc] init];
    MGSAttributeOverlayTextStorage *realTextStorage = [[MGSAttributeOverlayTextStorage alloc] initWithParentTextStorage:_backingTextStorage];
	
	// create textview
	_textView = [[SMLTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
    [self.textView.layoutManager replaceTextStorage:realTextStorage];
	[self.scrollView setDocumentView:self.textView];
	
	// create line numbers
	_gutterView = [[MGSLineNumberView alloc] initWithScrollView:self.scrollView fragaria:self];
	[self.scrollView setVerticalRulerView:self.gutterView];
	[self.scrollView setHasVerticalRuler:YES];
	[self.scrollView setHasHorizontalRuler:NO];
	
	// syntaxColouring defaults
	self.textView.syntaxColouring.syntaxDefinitionName = [MGSSyntaxController standardSyntaxDefinitionName];
	self.textView.syntaxColouring.fragaria = self;
	
	// add scroll view to content view
	[self addSubview:self.scrollView];
	
	// update the gutter view
	self.showsGutter = YES;
	
	_syntaxErrorController = [[MGSSyntaxErrorController alloc] init];
	self.syntaxErrorController.lineNumberView = self.gutterView;
	self.syntaxErrorController.textView = self.textView;
	[self setShowsSyntaxErrors:YES];
	
	[self setAutoCompleteDelegate:nil];
 
    // Default Color Scheme; needs to be set up last
    self.colourScheme = [[MGSColourScheme alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:self.textView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)textDidChange:(NSNotification *)notification
{
    [self mgs_propagateValue:self.string forBinding:NSStringFromSelector(@selector(string))];
}


@end


#pragma mark - Implementation of Deprecated Methods


@implementation MGSFragariaView (MGSDeprecated)


/*
 * @property currentLineHighlightColour
 */
- (void)setCurrentLineHighlightColour:(NSColor *)currentLineHighlightColour
{
    self.textView.currentLineHighlightColour = currentLineHighlightColour;
    [self mgs_propagateValue:currentLineHighlightColour forBinding:NSStringFromSelector(@selector(currentLineHighlightColour))];
}

- (NSColor *)currentLineHighlightColour
{
    return self.textView.currentLineHighlightColour;
}


/*
 * @property defaultSyntaxErrorHighlightingColour
 */
- (void)setDefaultSyntaxErrorHighlightingColour:(NSColor *)defaultSyntaxErrorHighlightingColour
{
    _colourScheme.defaultSyntaxErrorHighlightingColour = defaultSyntaxErrorHighlightingColour;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:defaultSyntaxErrorHighlightingColour forBinding:NSStringFromSelector(@selector(defaultSyntaxErrorHighlightingColour))];
}

- (NSColor *)defaultSyntaxErrorHighlightingColour
{
    return self.colourScheme.defaultSyntaxErrorHighlightingColour;
}


/*
 * @property textInvisibleCharactersColour
 */
- (void)setTextInvisibleCharactersColour:(NSColor *)textInvisibleCharactersColour
{
    self.textView.textInvisibleCharactersColour = textInvisibleCharactersColour;
    [self mgs_propagateValue:textInvisibleCharactersColour forBinding:NSStringFromSelector(@selector(textInvisibleCharactersColour))];
}

- (NSColor *)textInvisibleCharactersColour
{
    return self.textView.textInvisibleCharactersColour;
}


/*
 * @property textColor
 */
- (void)setTextColor:(NSColor *)textColor
{
    self.textView.textColor = textColor;
    [self mgs_propagateValue:textColor forBinding:NSStringFromSelector(@selector(textColor))];
}

- (NSColor *)textColor
{
    return self.textView.textColor;
}


/*
 * @property backgroundColor
 */
- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    self.textView.backgroundColor = backgroundColor;
    [self mgs_propagateValue:backgroundColor forBinding:NSStringFromSelector(@selector(backgroundColor))];
}

- (NSColor *)backgroundColor
{
    return self.textView.backgroundColor;
}


/*
 * @property insertionPointColor
 */
- (void)setInsertionPointColor:(NSColor *)insertionPointColor
{
    self.textView.insertionPointColor = insertionPointColor;
    [self mgs_propagateValue:insertionPointColor forBinding:NSStringFromSelector(@selector(insertionPointColor))];
}

- (NSColor *)insertionPointColor
{
    return self.textView.insertionPointColor;
}


/*
 * @property colourForAutocomplete
 */
- (void)setColourForAutocomplete:(NSColor *)colourForAutocomplete
{
    _colourScheme.colourForAutocomplete = colourForAutocomplete;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:colourForAutocomplete forBinding:NSStringFromSelector(@selector(colourForAutocomplete))];
}

- (NSColor *)colourForAutocomplete
{
    return _colourScheme.colourForAutocomplete;
}


/*
 * @property colourForAttributes
 */
- (void)setColourForAttributes:(NSColor *)colourForAttributes
{
    _colourScheme.colourForAttributes = colourForAttributes;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:colourForAttributes forBinding:NSStringFromSelector(@selector(colourForAttributes))];
}

- (NSColor *)colourForAttributes
{
    return _colourScheme.colourForAttributes;
}


/*
 * @property colourForCommands
 */
- (void)setColourForCommands:(NSColor *)colourForCommands
{
    _colourScheme.colourForCommands = colourForCommands;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:colourForCommands forBinding:NSStringFromSelector(@selector(colourForCommands))];
}

- (NSColor *)colourForCommands
{
    return _colourScheme.colourForCommands;
}


/*
 * @property colourForComments
 */
- (void)setColourForComments:(NSColor *)colourForComments
{
    _colourScheme.colourForComments = colourForComments;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:colourForComments forBinding:NSStringFromSelector(@selector(colourForComments))];
}

- (NSColor *)colourForComments
{
    return _colourScheme.colourForComments;
}


/*
 * @property colourForInstructions
 */
- (void)setColourForInstructions:(NSColor *)colourForInstructions
{
    _colourScheme.colourForInstructions = colourForInstructions;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:colourForInstructions forBinding:NSStringFromSelector(@selector(colourForInstructions))];
}

- (NSColor *)colourForInstructions
{
    return _colourScheme.colourForInstructions;
}


/*
 * @property colourForKeywords
 */
- (void)setColourForKeywords:(NSColor *)colourForKeywords
{
    _colourScheme.colourForKeywords = colourForKeywords;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:colourForKeywords forBinding:NSStringFromSelector(@selector(colourForKeywords))];
}

- (NSColor *)colourForKeywords
{
    return _colourScheme.colourForKeywords;
}


/*
 * @property colourForNumbers
 */
- (void)setColourForNumbers:(NSColor *)colourForNumbers
{
    _colourScheme.colourForNumbers = colourForNumbers;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:colourForNumbers forBinding:NSStringFromSelector(@selector(colourForNumbers))];
}

- (NSColor *)colourForNumbers
{
    return _colourScheme.colourForNumbers;
}


/*
 * @property colourForStrings
 */
- (void)setColourForStrings:(NSColor *)colourForStrings
{
    _colourScheme.colourForStrings = colourForStrings;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:colourForStrings forBinding:NSStringFromSelector(@selector(colourForStrings))];
}

- (NSColor *)colourForStrings
{
    return _colourScheme.colourForStrings;
}


/*
 * @property colourForVariables
 */
- (void)setColourForVariables:(NSColor *)colourForVariables
{
    _colourScheme.colourForVariables = colourForVariables;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:colourForVariables forBinding:NSStringFromSelector(@selector(colourForVariables))];
}

- (NSColor *)colourForVariables
{
    return _colourScheme.colourForVariables;
}


/*
 * @property coloursAttributes
 */
- (void)setColoursAttributes:(BOOL)coloursAttributes
{
    _colourScheme.coloursAttributes = coloursAttributes;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:@(coloursAttributes) forBinding:NSStringFromSelector(@selector(coloursAttributes))];
}

- (BOOL)coloursAttributes
{
    return _colourScheme.coloursAttributes;
}

/*
 * @property coloursAutocomplete
 */
- (void)setColoursAutocomplete:(BOOL)coloursAutocomplete
{
    _colourScheme.coloursAutocomplete = coloursAutocomplete;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:@(coloursAutocomplete) forBinding:NSStringFromSelector(@selector(coloursAutocomplete))];
}

- (BOOL)coloursAutocomplete
{
    return _colourScheme.coloursAutocomplete;
}


/*
 * @property coloursCommands
 */
- (void)setColoursCommands:(BOOL)coloursCommands
{
    _colourScheme.coloursCommands = coloursCommands;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:@(coloursCommands) forBinding:NSStringFromSelector(@selector(coloursCommands))];
}

- (BOOL)coloursCommands
{
    return _colourScheme.coloursCommands;
}


/*
 * @property coloursComments
 */
- (void)setColoursComments:(BOOL)coloursComments
{
    _colourScheme.coloursComments = coloursComments;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:@(coloursComments) forBinding:NSStringFromSelector(@selector(coloursComments))];
}

- (BOOL)coloursComments
{
    return _colourScheme.coloursComments;
}


/*
 * @property coloursInstructions
 */
- (void)setColoursInstructions:(BOOL)coloursInstructions
{
    _colourScheme.coloursInstructions = coloursInstructions;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:@(coloursInstructions) forBinding:NSStringFromSelector(@selector(coloursInstructions))];
}

- (BOOL)coloursInstructions
{
    return _colourScheme.coloursInstructions;
}


/*
 * @property coloursKeywords
 */
- (void)setColoursKeywords:(BOOL)coloursKeywords
{
    _colourScheme.coloursKeywords = coloursKeywords;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:@(coloursKeywords) forBinding:NSStringFromSelector(@selector(coloursKeywords))];
}

- (BOOL)coloursKeywords
{
    return _colourScheme.coloursKeywords;
}


/*
 * @property coloursNumbers
 */
- (void)setColoursNumbers:(BOOL)coloursNumbers
{
    _colourScheme.coloursNumbers = coloursNumbers;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:@(coloursNumbers) forBinding:NSStringFromSelector(@selector(coloursNumbers))];
}

- (BOOL)coloursNumbers
{
    return _colourScheme.coloursNumbers;
}


/*
 * @property coloursStrings
 */
- (void)setColoursStrings:(BOOL)coloursStrings
{
    _colourScheme.coloursStrings = coloursStrings;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:@(coloursStrings) forBinding:NSStringFromSelector(@selector(coloursStrings))];
}

- (BOOL)coloursStrings
{
    return _colourScheme.coloursStrings;
}


/*
 * @property coloursVariables
*/
- (void)setColoursVariables:(BOOL)coloursVariables
{
    _colourScheme.coloursVariables = coloursVariables;
    [self colourSchemeHasChanged];
    [self mgs_propagateValue:@(coloursVariables) forBinding:NSStringFromSelector(@selector(coloursVariables))];
}

- (BOOL)coloursVariables
{
    return _colourScheme.coloursVariables;
}


@end
