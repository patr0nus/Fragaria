//
//  MGSPrefsColourPropertiesViewController.h
//  Fragaria
//
//  Created by Jim Derry on 3/15/15.
//
//

#import "MGSPrefsViewController.h"

@class MGSMutableColourScheme;


/**
 *  MGSPrefsColourPropertiesViewController provides a basic class for managing
 *  instances of the MGSPrefsColourProperties nib.
 **/

@interface MGSPrefsColourPropertiesViewController : MGSPrefsViewController


@property (nonatomic, weak) IBOutlet NSObjectController *currentSchemeObjectController;


@property (nonatomic, strong) MGSMutableColourScheme *currentScheme;


@end
