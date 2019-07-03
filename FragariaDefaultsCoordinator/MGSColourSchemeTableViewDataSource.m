//
//  MGSColourSchemeTableViewController.m
//  FragariaDefaultsCoordinator
//
//  Created by Daniele Cattaneo on 02/07/2019.
//

#import "MGSColourSchemeTableViewDataSource.h"
#import "MGSFragariaView+Definitions.h"
#import "MGSMutableColourScheme.h"
#import "MGSSyntaxController.h"
#import "NSObject+Fragaria.h"


@implementation MGSColourSchemeTableViewDataSource
{
    NSArray<MGSSyntaxGroup> *_colouringGroupsCache;
}


+ (void)initialize
{
    if ([self class] != [MGSColourSchemeTableViewDataSource class])
        return;
    [self exposeBinding:NSStringFromSelector(@selector(currentScheme))];
}


- (instancetype)init
{
    self = [super init];
    _currentScheme = [[MGSMutableColourScheme alloc] init];
    return self;
}


- (void)setTableView:(NSTableView *)tableView
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSNib *tcvnib = [[NSNib alloc] initWithNibNamed:@"MGSColourSchemeTableCellView" bundle:bundle];
    [tableView registerNib:tcvnib forIdentifier:@"normalRow"];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView reloadData];
    _tableView = tableView;
}


- (void)setCurrentScheme:(MGSMutableColourScheme *)currentScheme
{
    _currentScheme = currentScheme;
    [self.tableView reloadData];
    [self mgs_propagateValue:_currentScheme forBinding:NSStringFromSelector(@selector(currentScheme))];
}


- (void)updateView:(MGSColourSchemeTableCellView *)theView
{
    [theView updateView];
}


#pragma mark - Highlighting Table View Delegate / Data Source


- (NSArray<MGSSyntaxGroup> *)colouringGroups
{
    if (!_colouringGroupsCache) {
        NSArray *tmp = [[MGSSyntaxController sharedInstance] syntaxGroupsForParsers];
        _colouringGroupsCache = [tmp sortedArrayUsingSelector:@selector(compare:)];
    }
    return _colouringGroupsCache;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self colouringGroups] count];
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    MGSColourSchemeTableCellView *view = [tableView makeViewWithIdentifier:@"normalRow" owner:self];
    MGSSyntaxGroup group = [[self colouringGroups] objectAtIndex:row];
    view.syntaxGroup = group;
    view.parentVc = self;
    [self updateView:view];
    return view;
}


@end


@implementation MGSColourSchemeTableCellView


- (void)updateView
{
    MGSMutableColourScheme *scheme = self.parentVc.currentScheme;
    MGSSyntaxGroup resolvedGrp = [scheme resolveSyntaxGroup:self.syntaxGroup];
    
    BOOL colors = [scheme coloursSyntaxGroup:resolvedGrp];
    
    self.label.stringValue = [[MGSSyntaxController sharedInstance] localizedDisplayNameForSyntaxGroup:self.syntaxGroup];
    
    self.colorWell.color = [scheme colourForSyntaxGroup:resolvedGrp];
    self.colorWell.enabled = colors;
    
    self.enabled.state = colors ? NSControlStateValueOn : NSControlStateValueOff;
    
    MGSFontVariant variant = [scheme fontVariantForSyntaxGroup:resolvedGrp];
    [self.textVariant setSelected:!!(variant & MGSFontVariantBold) forSegment:0];
    [self.textVariant setSelected:!!(variant & MGSFontVariantItalic) forSegment:1];
    [self.textVariant setSelected:!!(variant & MGSFontVariantUnderline) forSegment:2];
    self.textVariant.enabled = colors;
}


- (IBAction)updateScheme:(id)sender
{
    MGSMutableColourScheme *scheme = self.parentVc.currentScheme;
    
    BOOL newColors = self.enabled.state == NSControlStateValueOn ? YES : NO;
    
    NSColor *newColor = self.colorWell.color;
    
    MGSFontVariant variant = 0;
    variant += [self.textVariant isSelectedForSegment:0] ? MGSFontVariantBold : 0;
    variant += [self.textVariant isSelectedForSegment:1] ? MGSFontVariantItalic : 0;
    variant += [self.textVariant isSelectedForSegment:2] ? MGSFontVariantUnderline : 0;
    
    [scheme setOptions:@{
            MGSColourSchemeGroupOptionKeyEnabled: @(newColors),
            MGSColourSchemeGroupOptionKeyColour: newColor,
            MGSColourSchemeGroupOptionKeyFontVariant: @(variant)}
        forSyntaxGroup:self.syntaxGroup];
    
    [self.parentVc updateView:self];
    [self.parentVc mgs_propagateValue:scheme forBinding:NSStringFromSelector(@selector(currentScheme))];
}


- (void)prepareForReuse
{
    [self.colorWell deactivate];
}


@end

