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

#import "MGSSyntaxController.h"
#import "MGSSyntaxParser.h"
#import "MGSParserFactory.h"
#import "MGSStandardParser.h"
#import "MGSClassicFragariaParserFactory.h"


static MGSSyntaxController *sharedInstance = nil;


@interface MGSSyntaxController()

@property (nonatomic, strong) NSMutableArray<id <MGSParserFactory>> *allFactories;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id <MGSParserFactory>> *definitionToFactory;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *disambiguatedDefinitions;

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
    _disambiguatedDefinitions = [[NSMutableDictionary alloc] init];
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
            [self.disambiguatedDefinitions setObject:def forKey:disambigDef];
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
        [res addObjectsFromArray:names];
    }
    return res;
}


- (NSArray<NSString *> *)syntaxDefinitionNamesWithUTI:(NSString *)uti
{
    NSMutableArray *res = [NSMutableArray array];
    for (id <MGSParserFactory> factory in self.allFactories) {
        if (![factory respondsToSelector:@selector(syntaxDefinitionNamesWithUTI:)])
            continue;
        NSArray *names = [factory syntaxDefinitionNamesWithUTI:uti];
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
        [res addObjectsFromArray:names];
    }
    return res;
}


- (MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)syndef
{
    id <MGSParserFactory> factory = [self.definitionToFactory objectForKey:syndef];
    if (!factory)
        return nil;
    NSString *realid = [self.disambiguatedDefinitions objectForKey:syndef];
    if (!realid)
        realid = syndef;
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
