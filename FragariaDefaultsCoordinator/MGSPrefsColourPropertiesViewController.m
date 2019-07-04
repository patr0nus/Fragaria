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
#import "MGSSyntaxController.h"
#import "MGSColourSchemeTableViewDataSource.h"


static void *ColourSchemeChangedContext = &ColourSchemeChangedContext;
static void *DefaultsChangedContext = &DefaultsChangedContext;


@interface MGSManagedColourSchemeTableViewDataSource : MGSColourSchemeTableViewDataSource

@property (nonatomic) IBOutlet MGSPrefsColourPropertiesViewController *parentVc;

@end


@interface MGSPrefsColourPropertiesViewController ()

@property (nonatomic) IBOutlet NSView *paneScheme;
@property (nonatomic) IBOutlet NSView *paneEditorColours;
@property (nonatomic) IBOutlet NSView *paneSyntaxColours;
@property (nonatomic) IBOutlet NSView *paneOtherSettings;

@property (nonatomic) IBOutlet MGSManagedColourSchemeTableViewDataSource *tableViewDs;

@end


@implementation MGSPrefsColourPropertiesViewController
{
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
    
    self.tableViewDs.currentScheme = _currentScheme;
    
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
    self.tableViewDs.currentScheme = currentScheme;
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
    updatingFromDefaults = NO;
}


- (NSString *)toolbarItemLabel
{
    NSBundle *b = [NSBundle bundleForClass:[MGSPrefsColourPropertiesViewController class]];
    return NSLocalizedStringFromTableInBundle(@"Colors", nil, b, @"Toolbar item name for the Colors preference pane");
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


@end


@implementation MGSManagedColourSchemeTableViewDataSource


- (void)updateView:(MGSColourSchemeTableCellView *)theView
{
    [super updateView:theView];
    
    NSNumber *isManagedGlobal = [self.parentVc.managedGlobalProperties valueForKey:@"colourScheme"];
    
    theView.label.font = [isManagedGlobal boolValue] ? [NSFont boldSystemFontOfSize:0.0] : [NSFont systemFontOfSize:0.0];
    
    NSString *tooltip = [[NSValueTransformer valueTransformerForName:@"MGSBoolToGlobalHintTransformer"] transformedValue:isManagedGlobal];
    theView.label.toolTip = tooltip;
}


@end

