//
//  MGSColourScheme.m
//  Fragaria
//
//  Created by Jim Derry on 3/16/15.
//
//

#import "MGSColourScheme.h"
#import "MGSFragariaView+Definitions.h"
#import "MGSColourToPlainTextTransformer.h"
#import "NSColor+TransformedCompare.h"
#import "MGSColourSchemeController.h"
#import "MGSMutableColourScheme.h"
#import "MGSColourSchemePrivate.h"


NSString * const MGSColourSchemeErrorDomain = @"MGSColourSchemeErrorDomain";

NSString * const MGSColourSchemeKeyCurrentLineHighlightColour    = @"currentLineHighlightColour";
NSString * const MGSColourSchemeKeyDefaultErrorHighlightingColor = @"defaultSyntaxErrorHighlightingColour";
NSString * const MGSColourSchemeKeyTextInvisibleCharactersColour = @"textInvisibleCharactersColour";
NSString * const MGSColourSchemeKeyTextColor                     = @"textColor";
NSString * const MGSColourSchemeKeyBackgroundColor               = @"backgroundColor";
NSString * const MGSColourSchemeKeyInsertionPointColor           = @"insertionPointColor";

NSString * const MGSColourSchemeKeyColourForAutocomplete = @"colourForAutocomplete";
NSString * const MGSColourSchemeKeyColourForAttributes   = @"colourForAttributes";
NSString * const MGSColourSchemeKeyColourForCommands     = @"colourForCommands";
NSString * const MGSColourSchemeKeyColourForComments     = @"colourForComments";
NSString * const MGSColourSchemeKeyColourForInstructions = @"colourForInstructions";
NSString * const MGSColourSchemeKeyColourForKeywords     = @"colourForKeywords";
NSString * const MGSColourSchemeKeyColourForNumbers      = @"colourForNumbers";
NSString * const MGSColourSchemeKeyColourForStrings      = @"colourForStrings";
NSString * const MGSColourSchemeKeyColourForVariables    = @"colourForVariables";

NSString * const MGSColourSchemeKeyColoursAttributes     = @"coloursAttributes";
NSString * const MGSColourSchemeKeyColoursAutocomplete   = @"coloursAutocomplete";
NSString * const MGSColourSchemeKeyColoursCommands       = @"coloursCommands";
NSString * const MGSColourSchemeKeyColoursComments       = @"coloursComments";
NSString * const MGSColourSchemeKeyColoursInstructions   = @"coloursInstructions";
NSString * const MGSColourSchemeKeyColoursKeywords       = @"coloursKeywords";
NSString * const MGSColourSchemeKeyColoursNumbers        = @"coloursNumbers";
NSString * const MGSColourSchemeKeyColoursStrings        = @"coloursStrings";
NSString * const MGSColourSchemeKeyColoursVariables      = @"coloursVariables";



@implementation MGSColourScheme


#pragma mark - Initializers


/*
 * - initWithDictionary:
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
{
    self = [super init];
    
    NSDictionary *defaults = [[self class] defaultValues];
    NSMutableDictionary *tmp = [defaults mutableCopy];
    [tmp addEntriesFromDictionary:dictionary];
    NSDictionary *safe = [tmp dictionaryWithValuesForKeys:[defaults allKeys]];
    [self setPropertiesFromDictionary:safe];

    return self;
}


- (instancetype)initWithFragaria:(MGSFragariaView *)fragaria displayName:(NSString *)name
{
    NSArray *keys = [[self class] propertiesOfScheme];
    NSDictionary *dict = [fragaria dictionaryWithValuesForKeys:keys];
    self = [self initWithDictionary:dict];
    _displayName = name;
    return self;
}


/*
 * - initWithFile:
 */
- (instancetype)initWithSchemeFileURL:(NSURL *)file error:(NSError **)err
{
    self = [self init];
    
    if (![self loadFromSchemeFileURL:file error:err])
        return nil;

    return self;
}


- (instancetype)initWithPropertyList:(id)plist error:(NSError **)err
{
    self = [self init];
    
    if (![self setPropertiesFromPropertyList:plist error:err])
        return nil;

    return self;
}


- (instancetype)initWithColourScheme:(MGSColourScheme *)scheme
{
    return [self initWithDictionary:[scheme dictionaryRepresentation]];
}


/*
 * - init
 */
- (instancetype)init
{
	return [self initWithDictionary:@{}];
}


+ (instancetype)defaultColorSchemeForAppearance:(NSAppearance *)appearance
{
    return [[self alloc] initWithDictionary:[self defaultValuesForAppearance:appearance]];
}


#pragma mark - General Properties


- (void)setPropertiesFromDictionary:(NSDictionary *)dictionaryRepresentation
{
    [self setValuesForKeysWithDictionary:dictionaryRepresentation];
}


- (BOOL)setPropertiesFromPropertyList:(id)fileContents error:(NSError **)err
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSValueTransformer *xformer = [NSValueTransformer valueTransformerForName:@"MGSColourToPlainTextTransformer"];
    
    NSSet *stringKeys = [[self class] propertiesOfTypeString];
    NSSet *colorKeys = [[self class] propertiesOfTypeColor];
    NSSet *boolKeys = [[self class] propertiesOfTypeBool];
    
    if (![fileContents isKindOfClass:[NSDictionary class]])
        goto wrongFormat;
    
    for (NSString *key in fileContents) {
        id object;
    
        if ([stringKeys containsObject:key]) {
            object = [fileContents objectForKey:key];
            if (![object isKindOfClass:[NSString class]])
                goto wrongFormat;
            
        } else if ([colorKeys containsObject:key]) {
            NSString *data = [fileContents objectForKey:key];
            if (![data isKindOfClass:[NSString class]])
                goto wrongFormat;
            object = [xformer reverseTransformedValue:[fileContents objectForKey:key]];
            if (![object isKindOfClass:[NSColor class]])
                goto wrongFormat;
            
        } else if ([boolKeys containsObject:key]) {
            object = [fileContents objectForKey:key];
            if (![object isKindOfClass:[NSNumber class]])
                goto wrongFormat;
            
        } else {
            NSLog(@"unrecognized key %@ when loading colour scheme from deserialized plist", key);
            continue;
        }
    
        [dictionary setObject:object forKey:key];
    }
    
    [self setPropertiesFromDictionary:dictionary];
    return YES;
    
    
wrongFormat:
    if (err)
        *err = [NSError errorWithDomain:MGSColourSchemeErrorDomain code:MGSColourSchemeWrongFileFormat userInfo:@{}];
    return NO;
}


- (NSDictionary *)dictionaryRepresentation
{
    return [self dictionaryWithValuesForKeys:[[[self class] propertiesAll] allObjects]];
}


- (NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	NSValueTransformer *xformer = [NSValueTransformer valueTransformerForName:@"MGSColourToPlainTextTransformer"];

    for (NSString *key in [self.dictionaryRepresentation allKeys])
    {
        if ([[[self class] propertiesOfTypeString] containsObject:key])
        {
            [dictionary setObject:[self valueForKey:key] forKey:key];
        }
        if ([[[self class] propertiesOfTypeColor] containsObject:key])
        {
			[dictionary setObject:[xformer transformedValue:[self valueForKey:key]] forKey:key];
        }
        if ([[[self class] propertiesOfTypeBool] containsObject:key])
        {
            [dictionary setObject:[self valueForKey:key] forKey:key];
        }
    }
    
    return dictionary;
}


#pragma mark - Instance Methods


/*
 * - isEqualToScheme:
 */
- (BOOL)isEqualToScheme:(MGSColourScheme *)scheme
{
    for (NSString *key in [[self class] propertiesOfScheme])
    {
        if ([[self valueForKey:key] isKindOfClass:[NSColor class]])
        {
            NSColor *color1 = [self valueForKey:key];
            NSColor *color2 = [scheme valueForKey:key];
            BOOL result = [color1 mgs_isEqualToColor:color2 transformedThrough:@"MGSColourToPlainTextTransformer"];
            if (!result)
            {
//                NSLog(@"KEY=%@ and SELF=%@ and EXTERNAL=%@", key, color1, color2);
                return result;
            }
        }
        else
        {
            BOOL result = [[self valueForKey:key] isEqual:[scheme valueForKey:key]];
            if (!result)
            {
//                NSLog(@"KEY=%@ and SELF=%@ and EXTERNAL=%@", key, [self valueForKey:key], [scheme valueForKey:key] );
                return result;
            }
        }
    }

    return YES;
}


- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if ([other isKindOfClass:[self class]] && [self class] != [other class])
        return [other isEqual:self];
    if (![self isKindOfClass:[other class]])
        return NO;
    return [self isEqualToScheme:other];
}


/*
 * - propertiesLoadFromFile:
 */
- (BOOL)loadFromSchemeFileURL:(NSURL *)file error:(NSError **)err
{
    NSInputStream *fp = [NSInputStream inputStreamWithURL:file];
    [fp open];
    if (!fp) {
        if (err)
            *err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
        return NO;
    }
    
    id fileContents = [NSPropertyListSerialization propertyListWithStream:fp options:NSPropertyListImmutable format:nil error:err];
    if (!fileContents)
        goto plistError;
    [fp close];

    return [self setPropertiesFromPropertyList:fileContents error:err];
    
plistError:
    if (err) {
        if ([[*err domain] isEqual:NSCocoaErrorDomain]) {
            if ([*err code] != NSPropertyListReadStreamError)
                *err = [NSError errorWithDomain:MGSColourSchemeErrorDomain code:MGSColourSchemeWrongFileFormat userInfo:@{NSUnderlyingErrorKey: *err}];
            else if ([[*err userInfo] objectForKey:NSUnderlyingErrorKey])
                *err = [[*err userInfo] objectForKey:NSUnderlyingErrorKey];
        }
    }
    return NO;
}


/*
 * - propertiesSaveToFile:
 */
- (BOOL)writeToSchemeFileURL:(NSURL *)file error:(NSError **)err
{
	NSDictionary *props = [self propertyListRepresentation];
    
    NSOutputStream *fp = [NSOutputStream outputStreamWithURL:file append:NO];
    if (!fp) {
        if (err)
            *err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
    }
    
    [fp open];
    BOOL res = [NSPropertyListSerialization writePropertyList:props toStream:fp format:NSPropertyListXMLFormat_v1_0 options:0 error:err];
    [fp close];
    
    return res;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<(%@ *)%p displayName=\"%@\">",
        NSStringFromClass([self class]),
        self,
        self.displayName];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[MGSMutableColourScheme alloc] initWithColourScheme:self];
}


#pragma mark - Category and Private


/*
 * - defaultValues
 */
+ (NSDictionary *)defaultValues
{
    return [[self class] defaultValuesForAppearance:nil];
}


+ (NSDictionary *)defaultValuesForAppearance:(NSAppearance *)appearance
{
    if (!appearance)
        appearance = [NSAppearance currentAppearance];
    
    NSString *dispName = NSLocalizedStringFromTableInBundle(
            @"Custom Settings", nil, [NSBundle bundleForClass:[self class]],
            @"Name for Custom Settings scheme.");
    NSMutableDictionary *common = [@{
        @"displayName"                                  : dispName,
        MGSColourSchemeKeyColoursAttributes             : @YES,
        MGSColourSchemeKeyColoursAutocomplete           : @NO,
        MGSColourSchemeKeyColoursCommands               : @YES,
        MGSColourSchemeKeyColoursComments               : @YES,
        MGSColourSchemeKeyColoursInstructions           : @YES,
        MGSColourSchemeKeyColoursKeywords               : @YES,
        MGSColourSchemeKeyColoursNumbers                : @YES,
        MGSColourSchemeKeyColoursStrings                : @YES,
        MGSColourSchemeKeyColoursVariables              : @YES,
    } mutableCopy];
    
    BOOL dark = NO;
    if (@available(macOS 10.14.0, *)) {
        NSString *best = [appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
        dark = [best isEqual:NSAppearanceNameDarkAqua];
    }
    
    NSDictionary *colors;
    if (!dark) {
        colors = @{
            MGSColourSchemeKeyTextInvisibleCharactersColour : [NSColor controlTextColor],
            MGSColourSchemeKeyTextColor                     : [NSColor textColor],
            MGSColourSchemeKeyBackgroundColor               : [NSColor textBackgroundColor],
            MGSColourSchemeKeyInsertionPointColor           : [NSColor textColor],
            MGSColourSchemeKeyCurrentLineHighlightColour    : [NSColor colorWithCalibratedRed:0.96f green:0.96f blue:0.71f alpha:1.0],
            MGSColourSchemeKeyColourForAutocomplete         : [NSColor colorWithCalibratedRed:0.84f green:0.41f blue:0.006f alpha:1.0],
            MGSColourSchemeKeyColourForAttributes           : [NSColor colorWithCalibratedRed:0.50f green:0.5f blue:0.2f alpha:1.0],
            MGSColourSchemeKeyColourForCommands             : [NSColor colorWithCalibratedRed:0.031f green:0.0f blue:0.855f alpha:1.0],
            MGSColourSchemeKeyColourForComments             : [NSColor colorWithCalibratedRed:0.0f green:0.45f blue:0.0f alpha:1.0],
            MGSColourSchemeKeyColourForInstructions         : [NSColor colorWithCalibratedRed:0.737f green:0.0f blue:0.647f alpha:1.0],
            MGSColourSchemeKeyColourForKeywords             : [NSColor colorWithCalibratedRed:0.737f green:0.0f blue:0.647f alpha:1.0],
            MGSColourSchemeKeyColourForNumbers              : [NSColor colorWithCalibratedRed:0.031f green:0.0f blue:0.855f alpha:1.0],
            MGSColourSchemeKeyColourForStrings              : [NSColor colorWithCalibratedRed:0.804f green:0.071f blue:0.153f alpha:1.0],
            MGSColourSchemeKeyColourForVariables            : [NSColor colorWithCalibratedRed:0.73f green:0.0f blue:0.74f alpha:1.0],
        };
    } else {
        colors = @{
            MGSColourSchemeKeyTextInvisibleCharactersColour : [NSColor colorWithCalibratedRed:0.905882f green:0.905882f blue:0.905882f alpha:1.0],
            MGSColourSchemeKeyTextColor                     : [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0],
            MGSColourSchemeKeyBackgroundColor               : [NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:1.0],
            MGSColourSchemeKeyInsertionPointColor           : [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0],
            MGSColourSchemeKeyColourForAutocomplete         : [NSColor colorWithCalibratedRed:0.84f green:0.41f blue:0.006f alpha:1.0],
            MGSColourSchemeKeyColourForAttributes           : [NSColor colorWithCalibratedRed:0.5f green:0.5f blue:0.2f alpha:1.0],
            MGSColourSchemeKeyColourForCommands             : [NSColor colorWithCalibratedRed:0.031f green:0.0f blue:0.855f alpha:1.0],
            MGSColourSchemeKeyColourForComments             : [NSColor colorWithCalibratedRed:0.254902f green:0.8f blue:0.270588f alpha:1.0],
            MGSColourSchemeKeyColourForInstructions         : [NSColor colorWithCalibratedRed:0.737f green:0.0f blue:0.647f alpha:1.0],
            MGSColourSchemeKeyColourForKeywords             : [NSColor colorWithCalibratedRed:0.827451f green:0.094118f blue:0.580392f alpha:1.0],
            MGSColourSchemeKeyColourForNumbers              : [NSColor colorWithCalibratedRed:0.466667f green:0.427451f blue:1.0f alpha:1.0],
            MGSColourSchemeKeyColourForStrings              : [NSColor colorWithCalibratedRed:1.0f green:0.172549f blue:0.219608f alpha:1.0],
            MGSColourSchemeKeyColourForVariables            : [NSColor colorWithCalibratedRed:0.73f green:0.0f blue:0.74f alpha:1.0],
        };
    }
    
    [common addEntriesFromDictionary:colors];
    return [common copy];
}


/*
 * + propertiesOfTypeBool
 */
+ (NSSet *)propertiesOfTypeBool
{
	return [NSSet setWithArray:@[
        MGSColourSchemeKeyColoursAttributes,
        MGSColourSchemeKeyColoursAutocomplete,
        MGSColourSchemeKeyColoursCommands,
        MGSColourSchemeKeyColoursComments,
        MGSColourSchemeKeyColoursInstructions,
        MGSColourSchemeKeyColoursKeywords,
        MGSColourSchemeKeyColoursNumbers,
        MGSColourSchemeKeyColoursStrings,
        MGSColourSchemeKeyColoursVariables,
    ]];
}


/*
 * + propertiesOfTypeColor
 */
+ (NSSet *)propertiesOfTypeColor
{
    NSSet *editorColours = [NSSet setWithArray:@[
        MGSColourSchemeKeyInsertionPointColor,
        MGSColourSchemeKeyCurrentLineHighlightColour,
        MGSColourSchemeKeyDefaultErrorHighlightingColor,
        MGSColourSchemeKeyTextColor,
        MGSColourSchemeKeyBackgroundColor,
        MGSColourSchemeKeyTextInvisibleCharactersColour,
    ]];
    NSSet *syntaxHighlightingColours = [NSSet setWithArray:@[
        MGSColourSchemeKeyColourForAutocomplete,
        MGSColourSchemeKeyColourForAttributes,
        MGSColourSchemeKeyColourForCommands,
        MGSColourSchemeKeyColourForComments,
        MGSColourSchemeKeyColourForInstructions,
        MGSColourSchemeKeyColourForKeywords,
        MGSColourSchemeKeyColourForNumbers,
        MGSColourSchemeKeyColourForStrings,
        MGSColourSchemeKeyColourForVariables,
    ]];
	return [editorColours setByAddingObjectsFromSet:syntaxHighlightingColours];
}


/*
 * + propertiesOfTypeString
 */
+ (NSSet *)propertiesOfTypeString
{
	return [NSSet setWithArray:@[@"displayName"]];
}


/*
 * + colourProperties
 */
+ (NSArray *)propertiesOfScheme
{
	return [[[[self class] propertiesOfTypeColor] setByAddingObjectsFromSet:
            [[self class] propertiesOfTypeBool]]
        allObjects];
}


/*
 * + propertiesAll
 */
+ (NSSet *)propertiesAll
{
    return [[[[self class] propertiesOfTypeColor] setByAddingObjectsFromSet:
             [[self class] propertiesOfTypeBool]] setByAddingObjectsFromSet:
            [[self class] propertiesOfTypeString]];
}


+ (NSArray <MGSColourScheme *> *)builtinColourSchemes
{
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    NSArray <NSURL *> *paths = [myBundle URLsForResourcesWithExtension:KMGSColourSchemeExt subdirectory:KMGSColourSchemesFolder];
    
    NSMutableArray <MGSColourScheme *> *res = [NSMutableArray array];
    for (NSURL *path in paths) {
        MGSColourScheme *sch = [[MGSColourScheme alloc] initWithSchemeFileURL:path error:nil];
        if (!sch) {
            NSLog(@"loading of scheme %@ failed", path);
            continue;
        }
        [res addObject:sch];
    }
    
    return res;
}


@end
