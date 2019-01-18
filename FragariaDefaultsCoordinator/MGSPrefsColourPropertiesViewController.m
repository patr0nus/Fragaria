//
//  MGSPrefsColourPropertiesViewController.m
//  Fragaria
//
//  Created by Jim Derry on 3/15/15.
//
//

#import "MGSPrefsColourPropertiesViewController.h"
#import "MGSFragariaView+Definitions.h"
#import "MGSMutableColourScheme.h"


static void *ColourSchemeChangedContext = &ColourSchemeChangedContext;
static void *DefaultsChangedContext = &DefaultsChangedContext;


@interface MGSPrefsColourPropertiesViewController ()

@property IBOutlet NSView *paneScheme;
@property IBOutlet NSView *paneEditorColours;
@property IBOutlet NSView *paneSyntaxColours;
@property IBOutlet NSView *paneOtherSettings;

@property IBOutlet NSTableView *hiliteTableView;

@end


@implementation MGSPrefsColourPropertiesViewController {
    BOOL updatingFromDefaults;
    BOOL savingToDefaults;
}

/*
 *  - init
 */
- (id)init
{
    NSBundle *bundle;
    
    self = [super init];
    
    MGSColourScheme *initial = [[self.userDefaultsController values] valueForKey:MGSFragariaDefaultsColourScheme];
    if (initial)
        _currentScheme = [initial mutableCopy];
    else
        _currentScheme = [[MGSMutableColourScheme alloc] init];
    
    [_currentScheme addObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation)) options:0 context:ColourSchemeChangedContext];
    
    bundle = [NSBundle bundleForClass:[MGSPrefsColourPropertiesViewController class]];
    [bundle loadNibNamed:@"MGSPrefsColourProperties" owner:self topLevelObjects:nil];
    
    [self.objectController addObserver:self forKeyPath:@"selection.colourScheme" options:0 context:DefaultsChangedContext];
    
    return self;
}


- (void)dealloc
{
    [_currentScheme removeObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation))];
    [self.objectController removeObserver:self forKeyPath:@"selection.colourScheme"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == ColourSchemeChangedContext) {
        [self saveColourSchemeToDefaults];
    } else if (context == DefaultsChangedContext) {
        [self updateColourSchemeFromDefaults];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)setCurrentScheme:(MGSMutableColourScheme *)currentScheme
{
    [_currentScheme removeObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation))];
    _currentScheme = currentScheme;
    [self.hiliteTableView reloadData];
    [_currentScheme addObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation)) options:NSKeyValueObservingOptionInitial context:ColourSchemeChangedContext];
}


- (void)saveColourSchemeToDefaults
{
    if (updatingFromDefaults)
        return;
    savingToDefaults = YES;
    MGSColourScheme *v = [self.currentScheme copy];
    [[self.userDefaultsController values] setValue:v forKey:NSStringFromSelector(@selector(colourScheme))];
    savingToDefaults = NO;
}


- (void)updateColourSchemeFromDefaults
{
    if (savingToDefaults)
        return;
    updatingFromDefaults = YES;
    MGSColourScheme *initial = [[self.userDefaultsController values] valueForKey:MGSFragariaDefaultsColourScheme];
    self.currentScheme = [initial mutableCopy];
    [self.hiliteTableView reloadData];
    updatingFromDefaults = NO;
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Colors", @"Toolbar item name for the Colors preference pane");
}


/*
 * - hideableViews
 */
- (NSDictionary *)propertiesForPanelSubviews
{
	return @{
			 NSStringFromSelector(@selector(paneScheme)) : [MGSFragariaView propertyGroupTheme],
			 NSStringFromSelector(@selector(paneEditorColours)) : [MGSFragariaView propertyGroupTheme],
			 NSStringFromSelector(@selector(paneSyntaxColours)) : [MGSFragariaView propertyGroupTheme],
			 NSStringFromSelector(@selector(paneOtherSettings)) : [MGSFragariaView propertyGroupColouringExtraOptions],
			 };
}


/*
 * - keysForPanelSubviews
 */
- (NSArray *)keysForPanelSubviews
{
    return @[
        NSStringFromSelector(@selector(paneScheme)),
        NSStringFromSelector(@selector(paneEditorColours)),
        NSStringFromSelector(@selector(paneSyntaxColours)),
        NSStringFromSelector(@selector(paneOtherSettings))
    ];
}


#pragma mark - Highlighting Table View Delegate / Data Source


- (NSArray<SMLSyntaxGroup> *)colouringGroups
{
    return @[SMLSyntaxGroupAutoComplete,
        SMLSyntaxGroupInstruction,
        SMLSyntaxGroupAttribute,
        SMLSyntaxGroupVariable,
        SMLSyntaxGroupKeyword,
        SMLSyntaxGroupComment,
        SMLSyntaxGroupCommand,
        SMLSyntaxGroupString,
        SMLSyntaxGroupNumber];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self colouringGroups] count];
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    MGSColourSchemeTableCellView *view = [tableView makeViewWithIdentifier:@"normalRow" owner:self];
    SMLSyntaxGroup group = [[self colouringGroups] objectAtIndex:row];
    view.syntaxGroup = group;
    view.parentVc = self;
    [view updateView];
    return view;
}


@end


@implementation MGSColourSchemeTableCellView


- (void)updateView
{
    MGSMutableColourScheme *scheme = self.parentVc.currentScheme;
    self.label.stringValue = self.syntaxGroup;
    self.colorWell.color = [scheme colourForSyntaxGroup:self.syntaxGroup];
    BOOL colors = [scheme coloursSyntaxGroup:self.syntaxGroup];
    self.enabled.state = colors ? NSControlStateValueOn : NSControlStateValueOff;
    self.colorWell.enabled = colors;
    NSNumber *isManagedGlobal = [self.parentVc.managedGlobalProperties valueForKey:@"colourScheme"];
    self.label.font = [isManagedGlobal boolValue] ? [NSFont boldSystemFontOfSize:0.0] : [NSFont systemFontOfSize:0.0];
    NSString *tooltip = [[NSValueTransformer valueTransformerForName:@"MGSBoolToGlobalHintTransformer"] transformedValue:isManagedGlobal];
    self.label.toolTip = tooltip;
}


- (IBAction)updateScheme:(id)sender
{
    MGSMutableColourScheme *scheme = self.parentVc.currentScheme;
    BOOL newColors = self.enabled.state == NSControlStateValueOn ? YES : NO;
    NSColor *newColor = self.colorWell.color;
    [scheme setColours:newColors syntaxGroup:self.syntaxGroup];
    [scheme setColour:newColor forSyntaxGroup:self.syntaxGroup];
    [self updateView];
}


- (void)prepareForReuse
{
    [self.colorWell deactivate];
}


@end

