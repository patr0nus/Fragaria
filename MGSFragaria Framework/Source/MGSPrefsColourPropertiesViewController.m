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

@end


@implementation MGSPrefsColourPropertiesViewController

/*
 *  - init
 */
- (id)init
{
    NSBundle *bundle;
    
    self = [super init];
    
    MGSColourScheme *initial = [[self.userDefaultsController values] valueForKey:NSStringFromSelector(@selector(colourScheme))];
    if (initial)
        _currentScheme = [initial mutableCopy];
    else
        _currentScheme = [[MGSMutableColourScheme alloc] init];
    [_currentScheme addObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation)) options:0 context:ColourSchemeChangedContext];
    
    bundle = [NSBundle bundleForClass:[MGSPrefsColourPropertiesViewController class]];
    [bundle loadNibNamed:@"MGSPrefsColourProperties" owner:self topLevelObjects:nil];
    
    return self;
}


- (void)dealloc
{
    [_currentScheme removeObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation))];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == ColourSchemeChangedContext) {
        [self saveColourSchemeToDefaults];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)setCurrentScheme:(MGSMutableColourScheme *)currentScheme
{
    [self saveColourSchemeToDefaults];
}


- (void)saveColourSchemeToDefaults
{
    MGSColourScheme *v = [self.currentScheme copy];
    [[self.userDefaultsController values] setValue:v forKey:NSStringFromSelector(@selector(colourScheme))];
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


@end
