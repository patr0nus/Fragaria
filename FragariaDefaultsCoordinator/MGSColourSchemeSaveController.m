//
//  MGSColourSchemeSaveController.m
//  Fragaria
//
//  Created by Jim Derry on 3/21/15.
//
//

#import "MGSColourSchemeSaveController.h"


@interface MGSColourSchemeSaveController ()

@property (nonatomic, strong) IBOutlet NSTextField *schemeNameField;

@property (nonatomic, strong) IBOutlet NSButton *bCancel;
@property (nonatomic, strong) IBOutlet NSButton *bSave;

@property (nonatomic, assign) BOOL saveButtonEnabled;
@property (nonatomic, assign) BOOL nameInUse;

@end


@implementation MGSColourSchemeSaveController
{
    void (^deleteCompletion)(BOOL);
}

/*
 * - init
 */
- (instancetype)init
{
    self = [self initWithWindowNibName:@"MGSColourSchemeSave" owner:self];
    return self;
}


/*
 * - awakeFromNib
 */
- (void)awakeFromNib
{
    [self.window setDefaultButtonCell:[self.bSave cell]];
}


#pragma mark - File Naming Sheet


/*
 * - closeSheet
 */
- (IBAction)closeSheet:(id)sender
{
    NSModalResponse response;
    
    if (sender == self.bSave) {
        response = NSModalResponseOK;
    } else {
        response = NSModalResponseCancel;
    }

    [self.window.sheetParent endSheet:self.window returnCode:response];
}


/*
 * @property saveButtonEnabled
 */
+ (NSSet *)keyPathsForValuesAffectingSaveButtonEnabled
{
    return [NSSet setWithObjects:@"schemeName", @"usedSchemeNames", nil];
}


- (BOOL)saveButtonEnabled
{
    return self.schemeName && [self.schemeName length] > 0 && ![self.usedSchemeNames containsObject:self.schemeName];
}


+ (NSSet *)keyPathsForValuesAffectingNameInUse
{
    return [NSSet setWithObjects:@"schemeName", @"usedSchemeNames", nil];
}


- (BOOL)nameInUse
{
    return [self.usedSchemeNames containsObject:self.schemeName];
}


@end
