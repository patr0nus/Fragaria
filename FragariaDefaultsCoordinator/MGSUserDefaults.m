//
//  MGSUserDefaults.m
//  Fragaria
//
//  Created by Jim Derry on 3/3/15.
//
//

#import "MGSUserDefaults.h"
#import "MGSColourScheme.h"


@implementation MGSUserDefaults


#pragma mark - Class Methods - Singletons


/*
 *  Provides a shared controller for `groupID`.
 *  @param groupID Indicates the identifier for this group
 *  of user defaults.
 */
+ (instancetype)sharedUserDefaultsForGroupID:(NSString *)groupID
{
	static NSMutableDictionary *instances;
	
	@synchronized(self) {

        if (!instances)
        {
            instances = [[NSMutableDictionary alloc] init];
        }

		if ([[instances allKeys] containsObject:groupID])
		{
			return [instances objectForKey:groupID];
		}
		
		MGSUserDefaults *newController = [[[self class] alloc] initWithGroupID:groupID];
		[instances setObject:newController forKey:groupID];
		return newController;
	}
}


/*
 *  Provides the shared controller for global defaults.
 */
+ (instancetype)sharedUserDefaults
{
	return [[self class] sharedUserDefaultsForGroupID:MGSUSERDEFAULTS_GLOBAL_ID];
}


#pragma mark - Instance Methods

/*
 *  - registerDefaults:
 */
- (void)registerDefaults:(NSDictionary *)registrationDictionary
{
    NSDictionary *groupDict = @{ self.groupID : registrationDictionary };
    [super registerDefaults:groupDict];
}


#pragma mark - Initializers


/*
 *  - initWithGroupID:
 */
- (instancetype)initWithGroupID:(NSString *)groupID
{
	if ((self = [super init]))
	{
		_groupID = groupID;
	}
	
	return self;	
}


/*
 *  - init
 *    Just in case someone tries to create an instance manually,
 *    force it to use the global defaults.
 */
- (instancetype)init
{
	return [self initWithGroupID:MGSUSERDEFAULTS_GLOBAL_ID];
}


#pragma mark - Other Overrides


/*
 *  - setObject:forKey
 *    All of the base class set*:forKey implement this.
 */
- (void)setObject:(id)value forKey:(NSString *)defaultName
{
	NSMutableDictionary *groupDict = [NSMutableDictionary dictionaryWithDictionary:[super objectForKey:self.groupID]];
	
	if (!groupDict)
	{
		groupDict = [[NSMutableDictionary alloc] init];
	}
	
	if (value)
	{
        id newval = [MGSUserDefaults defaultsObjectFromObject:value];
        [groupDict setObject:newval forKey:defaultName];
	}
	else
	{
		[groupDict removeObjectForKey:defaultName];
	}
	
	[super setObject:groupDict forKey:self.groupID];
}


/*
 *  - objectForKey:
 *    All of the base class *forKey: utilize this.
 */
- (id)objectForKey:(NSString *)defaultName
{
	NSDictionary *groupDict = [super objectForKey:self.groupID];
	
	if ([[groupDict allKeys] containsObject:defaultName])
	{
        id object = [groupDict valueForKey:defaultName];
        return [MGSUserDefaults objectFromDefaultsObject:object];
	}
 
    if ([defaultName isEqual:MGSFragariaDefaultsColourScheme]) {
        return [self migrateToColorSchemes];
    }
	
	return nil;
}


#pragma mark - Migration


- (MGSColourScheme *)migrateToColorSchemes
{
    NSDictionary *groupDict = [super objectForKey:self.groupID];
    
    /* these keys are intentionally hardcoded because old versions of Fragaria
     * can't change but the properties of MGSColourScheme in future versions
     * can */
    NSArray *oldKeys = @[
        @"currentLineHighlightColour",      @"defaultSyntaxErrorHighlightingColour",
        @"textInvisibleCharactersColour",   @"textColor",
        @"backgroundColor",                 @"insertionPointColor",
        @"colourForAutocomplete",           @"colourForAttributes",
        @"colourForCommands",               @"colourForComments",
        @"colourForInstructions",           @"colourForKeywords",
        @"colourForNumbers",                @"colourForStrings",
        @"colourForVariables",
        @"coloursAttributes",               @"coloursAutocomplete",
        @"coloursCommands",                 @"coloursComments",
        @"coloursInstructions",             @"coloursKeywords",
        @"coloursNumbers",                  @"coloursStrings",
        @"coloursVariables"
    ];
    NSDictionary *values = [groupDict dictionaryWithValuesForKeys:oldKeys];
    return [[MGSColourScheme alloc] initWithPropertyList:values error:nil];
}


#pragma mark - Utility Methods


+ (id)defaultsObjectFromObject:(id)obj
{
    if ([obj isKindOfClass:[NSData class]] ||
        [obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSDate class]] ||
        [obj isKindOfClass:[NSNumber class]]) {
        return obj;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *newdict = [NSMutableDictionary dictionary];
        [obj enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            id newk = [[self class] defaultsObjectFromObject:key];
            id newv = [[self class] defaultsObjectFromObject:obj];
            [newdict setObject:newv forKey:newk];
        }];
        return [newdict copy];
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newarray = [NSMutableArray arrayWithCapacity:[obj length]];
        for (id subobj in obj) {
            id newobj = [[self class] defaultsObjectFromObject:subobj];
            [newarray addObject:newobj];
        }
        return [newarray copy];
    }
    
    if ([obj isKindOfClass:[MGSColourScheme class]]) {
        NSMutableDictionary *dict = [[obj propertyListRepresentation] mutableCopy];
        [dict setObject:@"MGSColourScheme" forKey:@"_fragaria_class"];
        return [dict copy];
    }
    
    return [NSArchiver archivedDataWithRootObject:obj];
}


+ (id)objectFromDefaultsObject:(id)obj
{
    if ([obj isKindOfClass:[NSData class]]) {
        id unpackd = [NSUnarchiver unarchiveObjectWithData:obj];
        if (!unpackd)
            return obj;
        return unpackd;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSString *classid = [obj objectForKey:@"_fragaria_class"];
        
        if ([classid isEqual:@"MGSColourScheme"]) {
            NSMutableDictionary *fixedObj = [obj mutableCopy];
            [fixedObj removeObjectForKey:@"_fragaria_class"];
            MGSColourScheme *res = [[MGSColourScheme alloc] initWithPropertyList:fixedObj error:nil];
            if (res)
                return res;
        }
        
        NSMutableDictionary *newdict = [NSMutableDictionary dictionary];
        [obj enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            id newk = [[self class] objectFromDefaultsObject:key];
            id newv = [[self class] objectFromDefaultsObject:obj];
            [newdict setObject:newv forKey:newk];
        }];
        return [newdict copy];
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newarray = [NSMutableArray arrayWithCapacity:[obj length]];
        for (id subobj in obj) {
            id newobj = [[self class] objectFromDefaultsObject:subobj];
            [newarray addObject:newobj];
        }
        return [newarray copy];
    }
    
    /* Important: return the original object even if it could not have been found
     * in a plist or in the user defaults. There is code that relies on this. */
    return obj;
}


@end
