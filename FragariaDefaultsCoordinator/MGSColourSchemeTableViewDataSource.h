//
//  MGSColourSchemeTableViewController.h
//  FragariaDefaultsCoordinator
//
//  Created by Daniele Cattaneo on 02/07/2019.
//

#import <Cocoa/Cocoa.h>
#import <Fragaria/Fragaria.h>

NS_ASSUME_NONNULL_BEGIN

@class MGSMutableColourScheme;
@class MGSColourSchemeTableCellView;


/**
 *  A bindings-compatible controller-layer class for displaying and editing the contents of a
 *  MGSMutableColourScheme through a NSTableView.
 */
@interface MGSColourSchemeTableViewDataSource : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) MGSColourScheme *currentScheme;

@property (nonatomic) BOOL showGroupProperties;
@property (nonatomic) BOOL showGroupGlobalProperties;
@property (nonatomic) BOOL showHeaders;

- (void)updateView:(MGSColourSchemeTableCellView *)theView;
- (void)prepareForReuseView:(MGSColourSchemeTableCellView *)theView;

@property (nonatomic, readonly) NSArray<MGSSyntaxGroup> *colouringGroups;
@property (nonatomic, readonly) NSArray<NSString *> *globalProperties;
- (NSString *)localizedStringForGlobalProperty:(NSString *)prop;

@end


@interface MGSColourSchemeTableCellView: NSView

@property (nonatomic) IBOutlet NSButton *enabled;
@property (nonatomic) IBOutlet NSTextField *label;
@property (nonatomic) IBOutlet NSColorWell *colorWell;
@property (nonatomic) IBOutlet NSSegmentedControl *textVariant;

@property (nonatomic, weak) MGSColourSchemeTableViewDataSource *parentVc;
@property (nonatomic, nullable) MGSSyntaxGroup syntaxGroup;
@property (nonatomic, nullable) NSString *globalPropertyKeyPath;

- (void)updateView;
- (IBAction)updateScheme:(id)sender;

@end


NS_ASSUME_NONNULL_END
