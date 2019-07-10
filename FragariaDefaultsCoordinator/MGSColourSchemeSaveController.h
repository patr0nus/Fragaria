//
//  MGSColourSchemeSaveController.h
//  Fragaria
//
//  Created by Jim Derry on 3/21/15.
//
/// @cond PRIVATE

#import <Cocoa/Cocoa.h>

/**
 *  Provides a scheme naming service for MGSColourSchemeListController, as well
 *  as a file deletion confirmation service.
 **/
@interface MGSColourSchemeSaveController : NSWindowController


/**
 *  The name of the scheme. You can retrieve this after showSchemeNameGetter
 *  returns.
 **/
@property (nonatomic, strong) NSString *schemeName;

@end
