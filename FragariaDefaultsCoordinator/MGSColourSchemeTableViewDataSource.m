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


@interface MGSColourSchemeTableViewDataSource ()

@property (nonatomic, strong) MGSMutableColourScheme *editableScheme;

@end


@implementation MGSColourSchemeTableViewDataSource
{
    NSMutableArray *_tableRows;
    NSNib *_tableCellsNib;
    NSCache <NSString *, NSMutableArray *> *_tableCellsCache;
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
    
    _showGroupProperties = YES;
    _currentScheme = [[MGSMutableColourScheme alloc] init];
    
    NSBundle *bundle = [NSBundle bundleForClass:[MGSColourSchemeTableViewDataSource class]];
    _tableCellsNib = [[NSNib alloc] initWithNibNamed:@"MGSColourSchemeTableCellView" bundle:bundle];
    _tableRows = [NSMutableArray array];
    _tableCellsCache = [[NSCache alloc] init];
    [self _rebuild];
    
    return self;
}


- (void)setTableView:(NSTableView *)tableView
{
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


- (void)setCurrentScheme:(MGSColourScheme *)currentScheme
{
    _currentScheme = currentScheme;
    if ([_currentScheme isKindOfClass:[MGSMutableColourScheme class]])
        _editableScheme = (MGSMutableColourScheme *)_currentScheme;
    else
        _editableScheme = [_currentScheme mutableCopy];
    [self.tableView reloadData];
    [self mgs_propagateValue:_currentScheme forBinding:NSStringFromSelector(@selector(currentScheme))];
}


- (void)updateCurrentScheme
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(currentScheme))];
    if (_currentScheme != _editableScheme)
        _currentScheme = [_editableScheme copy];
    [self mgs_propagateValue:_currentScheme forBinding:NSStringFromSelector(@selector(currentScheme))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(currentScheme))];
}


- (void)setShowGroupProperties:(BOOL)showGroupProperties
{
    _showGroupProperties = showGroupProperties;
    [self _rebuild];
}


- (void)setShowGroupGlobalProperties:(BOOL)showGroupGlobalProperties
{
    _showGroupGlobalProperties = showGroupGlobalProperties;
    [self _rebuild];
}


- (void)setShowHeaders:(BOOL)showHeaders
{
    _showHeaders = showHeaders;
    [self _rebuild];
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


/*
 * View-based NSTableViews using -makeViewWithIdentifier:owner: to create views are allergic
 * to modal interface components like NSColorWheel, because while you want to deactivate NSColorWheel
 * in -prepareForReuse to avoid having the focus on the color wheel shuffle around the
 * table view with the view-reusing madness ensuing a -reloadData, this also causes the color wheel
 * to deactivate as soon as it is used.
 *
 *   To solve the issue, we avoid using -makeViewWithIdentifier:owner: and we keep a static array of
 * the table cells we are using to always return the same view for the same location in the table.
 * We rebuild the array only when the table *structure* changes.
 *
 *   Even though we could cheap out and reinstantiate the nib objects every time the view array
 * is rebuild, it turns out that even for small tables instantiating a nib is crazy slow. So we have to
 * basically reimplement the caching logic in -makeViewWithIdentifier:owner: to keep the UI from visibly
 * lagging.
 *
 *   Yes, @nibroc, cell-based NSTableViews were not that bad of an idea after all.
 */
- (id)_makeTableCellViewWithIdentifier:(NSString *)ident
{
    NSMutableArray *cacheForIdent = [_tableCellsCache objectForKey:ident];
    if (cacheForIdent && cacheForIdent.count > 0) {
        NSView *view = [cacheForIdent lastObject];
        [cacheForIdent removeLastObject];
        [view prepareForReuse];
        return view;
    }
    
    /* If you're curious, yes, this is almost exactly what NSTableView does in
     * -makeViewWithIdentifier:owner: */
    NSMutableArray *topLevelObj = [NSMutableArray array];
    [_tableCellsNib instantiateWithOwner:self topLevelObjects:&topLevelObj];
    for (id obj in topLevelObj) {
        if (![obj isKindOfClass:[NSView class]])
            continue;
        if ([[obj identifier] isEqual:ident])
            return obj;
    }
    return nil;
}


- (void)_prepareDisposalOfTableCellView:(NSView *)view
{
    NSMutableArray *cacheForIdent = [_tableCellsCache objectForKey:view.identifier];
    if (!cacheForIdent)
        cacheForIdent = [NSMutableArray array];
    [cacheForIdent addObject:view];
    [_tableCellsCache setObject:cacheForIdent forKey:view.identifier];
}


- (void)_rebuild
{
    NSBundle *b = [NSBundle bundleForClass:[MGSColourSchemeTableViewDataSource class]];
    
    for (NSView *row in _tableRows)
        [self _prepareDisposalOfTableCellView:row];
    [_tableRows removeAllObjects];
    
    if (self.showGroupGlobalProperties) {
        if (self.showHeaders) {
            NSTableCellView *view = [self _makeTableCellViewWithIdentifier:@"headerRow"];
            view.textField.stringValue = NSLocalizedStringFromTableInBundle(@"Global Properties", nil, b, @"Colour Scheme Table Header");
            [_tableRows addObject:view];
        }
        
        for (NSString *key in self.globalProperties) {
            MGSColourSchemeTableCellView *view = [self _makeTableCellViewWithIdentifier:@"normalRow"];
            view.globalPropertyKeyPath = key;
            view.parentVc = self;
            [_tableRows addObject:view];
        }
    }
    
    if (self.showGroupProperties) {
        if (self.showHeaders) {
            NSTableCellView *view = [self _makeTableCellViewWithIdentifier:@"headerRow"];
            view.textField.stringValue = NSLocalizedStringFromTableInBundle(@"Syntax Highlighting", nil, b, @"Colour Scheme Table Header");
            [_tableRows addObject:view];
        }
        
        for (NSString *group in self.colouringGroups) {
            MGSColourSchemeTableCellView *view = [self _makeTableCellViewWithIdentifier:@"normalRow"];
            view.syntaxGroup = group;
            view.parentVc = self;
            [_tableRows addObject:view];
        }
    }
    
    [self.tableView reloadData];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _tableRows.count;
}


- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    id rowview = _tableRows[row];
    if ([rowview isKindOfClass:[MGSColourSchemeTableCellView class]])
        return NO;
    return YES;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id view = _tableRows[row];
    if ([view isKindOfClass:[MGSColourSchemeTableCellView class]])
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
    MGSMutableColourScheme *scheme = self.parentVc.editableScheme;
    
    self.label.stringValue = [self.parentVc localizedStringForGlobalProperty:self.globalPropertyKeyPath];
    
    NSColor *color = [scheme valueForKeyPath:self.globalPropertyKeyPath];
    self.colorWell.color = color;
    self.colorWell.enabled = YES;
    
    self.enabled.hidden = YES;
    
    self.textVariant.hidden = YES;
}


- (void)_updateView_group
{
    MGSMutableColourScheme *scheme = self.parentVc.editableScheme;
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
    MGSMutableColourScheme *scheme = self.parentVc.editableScheme;
    
    NSColor *newColor = self.colorWell.color;
    [scheme setValue:newColor forKeyPath:self.globalPropertyKeyPath];
    
    [self.parentVc updateView:self];
    [self.parentVc updateCurrentScheme];
}


- (void)_updateScheme_group
{
    MGSMutableColourScheme *scheme = self.parentVc.editableScheme;
    
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
    [self.parentVc updateCurrentScheme];
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.parentVc prepareForReuseView:self];
    [self.colorWell deactivate];
    self.syntaxGroup = nil;
    self.globalPropertyKeyPath = nil;
}


@end

