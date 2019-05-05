/*
 MGSFragaria
 Written by Jonathan Mitchell, jonathan@mugginsoft.com
 Find the latest version at https://github.com/mugginsoft/Fragaria

 Smultron version 3.6b1, 2009-09-12
 Written by Peter Borg, pgw3@mac.com
 Find the latest version at http://smultron.sourceforge.net

 Copyright 2004-2009 Peter Borg

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use
 this file except in compliance with the License. You may obtain a copy of the
 License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed
 under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 CONDITIONS OF ANY KIND, either express or implied. See the License for the
 specific language governing permissions and limitations under the License.
 */

#define FRAGARIA_PRIVATE
#import "MGSSyntaxController.h"
#import "MGSSyntaxParser.h"
#import "MGSParserFactory.h"
#import "MGSStandardParser.h"
#import "MGSClassicFragariaParserFactory.h"


static MGSSyntaxController *sharedInstance = nil;


@interface MGSAmbiguousSyntaxDefinition : NSObject

@property (nonatomic, strong) id <MGSParserFactory> parserFactory;
@property (nonatomic, strong) NSString *factoryName;
@property (nonatomic, strong) NSString *exposedName;

@end


@implementation MGSAmbiguousSyntaxDefinition

@end


@interface MGSSyntaxController()

@property (nonatomic, strong) NSMutableArray<id <MGSParserFactory>> *allFactories;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id <MGSParserFactory>> *definitionToFactory;

@property (nonatomic, strong) NSMutableSet<NSString *> *ambiguousDefinitions;
@property (nonatomic, strong) NSMutableArray<MGSAmbiguousSyntaxDefinition *> *ambiguousDefinitionData;

@property (nonatomic) NSArray<MGSSyntaxGroup> *syntaxGroupsForParsers;

@end


@implementation MGSSyntaxController
{
    NSArray<NSString *> *_syntaxDefinitionNamesCache;
    NSMutableDictionary<MGSSyntaxGroup, NSString *> *_localizedGroupNameCache;
}


/*
 * + sharedInstance
 */
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] _init];
    });
	
	return sharedInstance;
}


+ (NSString *)standardSyntaxDefinitionName
{
	return [MGSStandardParser standardSyntaxDefinitionName];
}


- (id)_init
{
    self = [super init];
    
    _allFactories = [[NSMutableArray alloc] init];
    _definitionToFactory = [[NSMutableDictionary alloc] init];
    _ambiguousDefinitions = [[NSMutableSet alloc] init];
    _ambiguousDefinitionData = [[NSMutableArray alloc] init];
    _localizedGroupNameCache = [[NSMutableDictionary alloc] init];
    [self registerParserFactory:[[MGSStandardParser alloc] init]];
    [self registerParserFactory:[[MGSClassicFragariaParserFactory alloc] init]];
    
    return self;
}


- (instancetype)init
{
    return [[self class] sharedInstance];
}


- (void)registerParserFactory:(id<MGSParserFactory>)parserFactory
{
    [self willChangeValueForKey:@"syntaxDefinitionNames"];
    _syntaxDefinitionNamesCache = nil;
    
    [self.allFactories addObject:parserFactory];
    
    NSArray<NSString *> *defs = [parserFactory syntaxDefinitionNames];
    for (NSString *def in defs) {
        NSString *disambigDef = def;
        int counter = 1;
        while ([self.definitionToFactory objectForKey:disambigDef]) {
            disambigDef = [NSString stringWithFormat:@"%@ (%d)", def, counter];
            counter++;
        }
        if (counter != 1) {
            if (![self.ambiguousDefinitions containsObject:def]) {
                [self.ambiguousDefinitions addObject:def];
                id <MGSParserFactory> existing = [self.definitionToFactory objectForKey:def];
                MGSAmbiguousSyntaxDefinition *asd = [[MGSAmbiguousSyntaxDefinition alloc] init];
                asd.factoryName = def;
                asd.exposedName = def;
                asd.parserFactory = existing;
                [self.ambiguousDefinitionData addObject:asd];
            }
            [self.ambiguousDefinitions addObject:disambigDef];
            MGSAmbiguousSyntaxDefinition *asd = [[MGSAmbiguousSyntaxDefinition alloc] init];
            asd.factoryName = def;
            asd.exposedName = disambigDef;
            asd.parserFactory = parserFactory;
            [self.ambiguousDefinitionData addObject:asd];
        }
        
        [self.definitionToFactory setObject:parserFactory forKey:disambigDef];
    }
    
    if ([parserFactory respondsToSelector:@selector(syntaxGroupsForParsers)]) {
        NSMutableSet *syntaxGrps = [NSMutableSet setWithArray:self.syntaxGroupsForParsers];
        NSMutableSet *newGrps = [NSMutableSet setWithArray:parserFactory.syntaxGroupsForParsers];
        [newGrps minusSet:syntaxGrps];
        
        [syntaxGrps addObjectsFromArray:parserFactory.syntaxGroupsForParsers];
        self.syntaxGroupsForParsers = [syntaxGrps allObjects];
        
        if ([parserFactory respondsToSelector:@selector(localizedDisplayNameForSyntaxGroup:)]) {
            for (MGSSyntaxGroup grp in newGrps) {
                NSString *str = [parserFactory localizedDisplayNameForSyntaxGroup:grp];
                if (str)
                    [_localizedGroupNameCache setObject:str forKey:grp];
            }
        }
    }
    
    [self didChangeValueForKey:@"syntaxDefinitionNames"];
}


- (NSString *)ambiguousSyntaxDefinitionNameFromUniqueName:(NSString *)name
{
    if (![self.ambiguousDefinitions containsObject:name])
        return name;
    for (MGSAmbiguousSyntaxDefinition *sddata in self.ambiguousDefinitionData) {
        if ([sddata.exposedName isEqual:name])
            return sddata.factoryName;
    }
    [NSException raise:NSInternalInconsistencyException format:@"ambiguousDefinitions set is inconsistent with ambiguousDefinitionData (name = %@)", name];
    return nil;
}


- (NSString *)uniqueSyntaxDefinitionNameFromAmbiguousName:(NSString *)name parserFactory:(id <MGSParserFactory>)pf
{
    if (![self.ambiguousDefinitions containsObject:name])
        return name;
    for (MGSAmbiguousSyntaxDefinition *sddata in self.ambiguousDefinitionData) {
        if (sddata.parserFactory != pf)
            continue;
        if ([sddata.factoryName isEqual:name])
            return sddata.exposedName;
    }
    [NSException raise:NSInternalInconsistencyException format:@"ambiguousDefinitions set is inconsistent with ambiguousDefinitionData, or parser factory %@ is buggy (name = %@)", pf, name];
    return nil;
}


- (NSArray<NSString *> *)uniqueSyntaxDefinitionNamesFromAmbiguousNames:(NSArray<NSString *> *)names parserFactory:(id <MGSParserFactory>)pf
{
    NSMutableArray *res = [NSMutableArray array];
    for (NSString *name in names) {
        NSString *newName = [self uniqueSyntaxDefinitionNameFromAmbiguousName:name parserFactory:pf];
        [res addObject:newName];
    }
    return [res copy];
}


- (NSArray<NSString *> *)syntaxDefinitionNames
{
    if (_syntaxDefinitionNamesCache)
        return _syntaxDefinitionNamesCache;

    NSArray *raw = [self.definitionToFactory allKeys];
    _syntaxDefinitionNamesCache = [raw sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    return _syntaxDefinitionNamesCache;
}


- (NSArray<NSString *> *)syntaxDefinitionNamesWithExtension:(NSString *)extension
{
	NSMutableArray *res = [NSMutableArray array];
    for (id <MGSParserFactory> factory in self.allFactories) {
        if (![factory respondsToSelector:@selector(syntaxDefinitionNamesWithExtension:)])
            continue;
        NSArray *names = [factory syntaxDefinitionNamesWithExtension:extension];
        names = [self uniqueSyntaxDefinitionNamesFromAmbiguousNames:names parserFactory:factory];
        [res addObjectsFromArray:names];
    }
    return res;
}


- (NSArray <NSString *> *)extensionsForSyntaxDefinitionName:(NSString *)sdname
{
    id <MGSParserFactory> factory = [self.definitionToFactory objectForKey:sdname];
    if (!factory)
        return @[];
    if (![factory respondsToSelector:@selector(extensionsForSyntaxDefinitionName:)])
        return @[];
    NSString *realname = [self ambiguousSyntaxDefinitionNameFromUniqueName:sdname];
    return [factory extensionsForSyntaxDefinitionName:realname];
}


- (NSArray<NSString *> *)syntaxDefinitionNamesWithUTI:(NSString *)uti
{
    NSMutableArray *res = [NSMutableArray array];
    for (id <MGSParserFactory> factory in self.allFactories) {
        if (![factory respondsToSelector:@selector(syntaxDefinitionNamesWithUTI:)])
            continue;
        NSArray *names = [factory syntaxDefinitionNamesWithUTI:uti];
        names = [self uniqueSyntaxDefinitionNamesFromAmbiguousNames:names parserFactory:factory];
        [res addObjectsFromArray:names];
    }
    return res;
}


- (NSArray<NSString *> *)guessSyntaxDefinitionNamesFromFirstLine:(NSString *)firstLine
{
    NSMutableArray *res = [NSMutableArray array];
    for (id <MGSParserFactory> factory in self.allFactories) {
        if (![factory respondsToSelector:@selector(guessSyntaxDefinitionNamesFromFirstLine:)])
            continue;
        NSArray *names = [factory guessSyntaxDefinitionNamesFromFirstLine:firstLine];
        names = [self uniqueSyntaxDefinitionNamesFromAmbiguousNames:names parserFactory:factory];
        [res addObjectsFromArray:names];
    }
    return res;
}


- (MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)syndef
{
    id <MGSParserFactory> factory = [self.definitionToFactory objectForKey:syndef];
    if (!factory)
        return nil;
    NSString *realid = [self ambiguousSyntaxDefinitionNameFromUniqueName:syndef];
    return [factory parserForSyntaxDefinitionName:realid];
}


- (NSString *)localizedDisplayNameForSyntaxGroup:(MGSSyntaxGroup)syntaxGroup
{
    NSString *res = [_localizedGroupNameCache objectForKey:syntaxGroup];
    if (!res)
        return syntaxGroup;
    return res;
}


@end
