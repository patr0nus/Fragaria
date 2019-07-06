//
//  MGSColorSchemeOption.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 20/10/17.
//
/// @cond PRIVATE

#import "MGSMutableColourScheme.h"


/** Class which stores information for one menu entry of MGSColourSchemeListController. */
@interface MGSColourSchemeOption : NSObject


/** The colour scheme */
@property (nonatomic) MGSMutableColourScheme *colourScheme;

/** True if this scheme is a custom scheme not yet saved */
@property (nonatomic, assign, getter=isTransient) BOOL transient;

/** Indicates if this definition was loaded from a bundle. */
@property (nonatomic, assign) BOOL loadedFromBundle;

/** Indicates the complete and path and filename this instance was loaded
 *  from (if any). */
@property (nonatomic, strong) NSURL *sourceURL;


@end
