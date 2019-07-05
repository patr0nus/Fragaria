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

/*
 *  - init
 */
- (id)init
{
    NSBundle *bundle;
    
    self = [super init];
    bundle = [NSBundle bundleForClass:[MGSPrefsColourPropertiesViewController class]];
    [bundle loadNibNamed:@"MGSPrefsColourProperties" owner:self topLevelObjects:nil];
    
    [self.tableViewDs bind:@"currentScheme" toObject:self.objectController withKeyPath:@"selection.colourScheme" options:nil];
    
    return self;
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

