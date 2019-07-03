//
//  MGSPrefsColourPropertiesViewController.h
//  Fragaria
//
//  Created by Jim Derry on 3/15/15.
//
//

#import "MGSPrefsViewController.h"
#import "MGSSyntaxParserClient.h"

@class MGSMutableColourScheme;


/**
 *  MGSPrefsColourPropertiesViewController provides a basic class for managing
 *  instances of the MGSPrefsColourProperties nib.
 **/

@interface MGSPrefsColourPropertiesViewController : MGSPrefsViewController <NSTableViewDelegate, NSTableViewDataSource>


@property (nonatomic, weak) IBOutlet NSObjectController *currentSchemeObjectController;


@property (nonatomic, strong) MGSMutableColourScheme *currentScheme;


@end
