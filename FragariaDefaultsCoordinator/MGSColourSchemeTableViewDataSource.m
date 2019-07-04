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
    NSBundle *bundle = [NSBundle bundleForClass:[MGSColourSchemeTableViewDataSource class]];
    NSNib *tcvnib = [[NSNib alloc] initWithNibNamed:@"MGSColourSchemeTableCellView" bundle:bundle];
    [tableView registerNib:tcvnib forIdentifier:@"normalRow"];
    [tableView registerNib:tcvnib forIdentifier:@"headerRow"];
    
    tableView.rowHeight = 22;
    tableView.allowsEmptySelection = YES;
    tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    NSArray *otherColumns = [tableView tableColumns];
    for (NSUInteger i=1; i<otherColumns.count; i++)
        [tableView removeTableColumn:otherColumns[i]];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView reloadData];
    _tableView = tableView;
}


- (void)setCurrentScheme:(MGSMutableColourScheme *)currentScheme
{
    _currentScheme = currentScheme;
    [self.tableView reloadData];
    [self mgs_propagateValue:_currentScheme forBinding:NSStringFromSelector(@selector(currentScheme))];
}


- (void)setShowGroupGlobalProperties:(BOOL)showGroupGlobalProperties
{
    _showGroupGlobalProperties = showGroupGlobalProperties;
    [self.tableView reloadData];
}


- (void)setShowHeaders:(BOOL)showHeaders
{
    _showHeaders = showHeaders;
    [self.tableView reloadData];
}


- (void)updateView:(MGSColourSchemeTableCellView *)theView
{
    [theView updateView];
}


- (void)prepareForReuseView:(MGSColourSchemeTableCellView *)theView
{
}


#pragma mark - Highlighting Table View Delegate / Data Source


- (NSArray<MGSSyntaxGroup> *)colouringGroups
{
    static NSArray<MGSSyntaxGroup> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *tmp = [[MGSSyntaxController sharedInstance] syntaxGroupsForParsers];
        cache = [tmp sortedArrayUsingSelector:@selector(compare:)];
    });
    return cache;
}


- (NSArray<NSString *> *)globalProperties
{
    static NSArray<NSString *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = @[
            NSStringFromSelector(@selector(textColor)),
            NSStringFromSelector(@selector(backgroundColor)),
            NSStringFromSelector(@selector(textInvisibleCharactersColour)),
            NSStringFromSelector(@selector(currentLineHighlightColour)),
            NSStringFromSelector(@selector(defaultSyntaxErrorHighlightingColour)),
            NSStringFromSelector(@selector(insertionPointColor)),
        ];
    });
    return cache;
}


- (NSString *)localizedStringForGlobalProperty:(NSString *)prop
{
    static NSDictionary *localizedMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *b = [NSBundle bundleForClass:[MGSColourSchemeTableViewDataSource class]];
        localizedMap = @{
            NSStringFromSelector(@selector(textColor)):
                NSLocalizedStringFromTableInBundle(@"Text", nil, b, @"Color Scheme Table View Global Option"),
            NSStringFromSelector(@selector(backgroundColor)):
                NSLocalizedStringFromTableInBundle(@"Background", nil, b, @"Color Scheme Table View Global Option"),
            NSStringFromSelector(@selector(textInvisibleCharactersColour)):
                NSLocalizedStringFromTableInBundle(@"Invisible Characters", nil, b, @"Color Scheme Table View Global Option"),
            NSStringFromSelector(@selector(currentLineHighlightColour)):
                NSLocalizedStringFromTableInBundle(@"Selected Line Background", nil, b, @"Color Scheme Table View Global Option"),
            NSStringFromSelector(@selector(defaultSyntaxErrorHighlightingColour)):
                NSLocalizedStringFromTableInBundle(@"Syntax Error Background", nil, b, @"Color Scheme Table View Global Option"),
            NSStringFromSelector(@selector(insertionPointColor)):
                NSLocalizedStringFromTableInBundle(@"Insertion Point", nil, b, @"Color Scheme Table View Global Option")
        };
    });
    NSString *res = [localizedMap objectForKey:prop];
    return res ?: prop;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger header = self.showHeaders ? 1 : 0;
    if (!self.showGroupGlobalProperties) {
        return header + [[self colouringGroups] count];
    } else {
        return (header + [[self globalProperties] count]) + (header + [[self colouringGroups] count]);
    }
}


- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    if (!self.showHeaders)
        return NO;
    if (row == 0)
        return YES;
    if (self.showGroupGlobalProperties && row == (NSInteger)(1 + [[self globalProperties] count]))
        return YES;
    return NO;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    BOOL isGlobal;
    NSInteger groupRow;
    NSInteger header = self.showHeaders ? 1 : 0;
    
    NSInteger globalCutoff;
    if (self.showGroupGlobalProperties)
        globalCutoff = header + [[self globalProperties] count];
    else
        globalCutoff = 0;
    if (row < globalCutoff) {
        isGlobal = YES;
        groupRow = row;
    } else {
        isGlobal = NO;
        groupRow = row - globalCutoff;
    }
    groupRow = groupRow + (1 - header);
    
    /* headers */
    if (groupRow == 0) {
        NSTableCellView *view = [tableView makeViewWithIdentifier:@"headerRow" owner:self];
        NSBundle *b = [NSBundle bundleForClass:[MGSColourSchemeTableViewDataSource class]];
        if (isGlobal) {
            view.textField.stringValue = NSLocalizedStringFromTableInBundle(@"Global Properties", nil, b, @"Colour Scheme Table Header");
        } else {
            view.textField.stringValue = NSLocalizedStringFromTableInBundle(@"Syntax Highlighting", nil, b, @"Colour Scheme Table Header");
        }
        return view;
    }
    
    MGSColourSchemeTableCellView *view = [tableView makeViewWithIdentifier:@"normalRow" owner:self];
    if (isGlobal) {
        NSString *key = [[self globalProperties] objectAtIndex:groupRow-1];
        view.globalPropertyKeyPath = key;
        view.syntaxGroup = nil;
    } else {
        MGSSyntaxGroup group = [[self colouringGroups] objectAtIndex:groupRow-1];
        view.globalPropertyKeyPath = nil;
        view.syntaxGroup = group;
    }
    view.parentVc = self;
    [self updateView:view];
    return view;
}


@end


@implementation MGSColourSchemeTableCellView


- (void)updateView
{
    if (self.syntaxGroup == nil)
        [self _updateView_global];
    else
        [self _updateView_group];
}


- (void)_updateView_global
{
    MGSMutableColourScheme *scheme = self.parentVc.currentScheme;
    
    self.label.stringValue = [self.parentVc localizedStringForGlobalProperty:self.globalPropertyKeyPath];
    
    NSColor *color = [scheme valueForKeyPath:self.globalPropertyKeyPath];
    self.colorWell.color = color;
    self.colorWell.enabled = YES;
    
    self.enabled.hidden = YES;
    
    self.textVariant.hidden = YES;
}


- (void)_updateView_group
{
    MGSMutableColourScheme *scheme = self.parentVc.currentScheme;
    MGSSyntaxGroup resolvedGrp = [scheme resolveSyntaxGroup:self.syntaxGroup];
    
    BOOL colors = [scheme coloursSyntaxGroup:resolvedGrp];
    
    self.label.stringValue = [[MGSSyntaxController sharedInstance] localizedDisplayNameForSyntaxGroup:self.syntaxGroup];
    
    self.colorWell.color = [scheme colourForSyntaxGroup:resolvedGrp];
    self.colorWell.enabled = colors;
    
    self.enabled.hidden = NO;
    self.enabled.state = colors ? NSControlStateValueOn : NSControlStateValueOff;
    
    MGSFontVariant variant = [scheme fontVariantForSyntaxGroup:resolvedGrp];
    [self.textVariant setSelected:!!(variant & MGSFontVariantBold) forSegment:0];
    [self.textVariant setSelected:!!(variant & MGSFontVariantItalic) forSegment:1];
    [self.textVariant setSelected:!!(variant & MGSFontVariantUnderline) forSegment:2];
    self.textVariant.enabled = colors;
    self.textVariant.hidden = NO;
}


- (IBAction)updateScheme:(id)sender
{
    if (self.syntaxGroup == nil)
        [self _updateScheme_global];
    else
        [self _updateScheme_group];
}


- (void)_updateScheme_global
{
    MGSMutableColourScheme *scheme = self.parentVc.currentScheme;
    
    NSColor *newColor = self.colorWell.color;
    [scheme setValue:newColor forKeyPath:self.globalPropertyKeyPath];
    
    [self.parentVc updateView:self];
    [self.parentVc mgs_propagateValue:scheme forBinding:NSStringFromSelector(@selector(currentScheme))];
}


- (void)_updateScheme_group
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
    [super prepareForReuse];
    [self.colorWell deactivate];
    [self.parentVc prepareForReuseView:self];
}


@end

