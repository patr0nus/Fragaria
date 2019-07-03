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


@interface MGSColourSchemeTableViewDataSource : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) MGSMutableColourScheme *currentScheme;

- (void)updateView:(MGSColourSchemeTableCellView *)theView;

@end


@interface MGSColourSchemeTableCellView: NSView

@property (nonatomic) IBOutlet NSButton *enabled;
@property (nonatomic) IBOutlet NSTextField *label;
@property (nonatomic) IBOutlet NSColorWell *colorWell;
@property (nonatomic) IBOutlet NSSegmentedControl *textVariant;

@property (nonatomic, weak) MGSColourSchemeTableViewDataSource *parentVc;
@property (nonatomic) MGSSyntaxGroup syntaxGroup;

- (void)updateView;
- (IBAction)updateScheme:(id)sender;

@end


NS_ASSUME_NONNULL_END
