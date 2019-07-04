//
//  MGSClassicFragariaParserFactory.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 27/12/2018.
//

#import "MGSClassicFragariaParserFactory.h"
#import "MGSParserFactory.h"
#import "MGSClassicFragariaSyntaxDefinition.h"
#import "MGSClassicFragariaSyntaxParser.h"


NSString * const KMGSSyntaxDictionaryExt = @"plist";
NSString * const KMGSSyntaxDefinitionsFolder = @"Syntax Definitions";
NSString * const KMGSSyntaxGroupNamesFileName = @"SyntaxGroupNames";
NSString * const KMGSSyntaxGroupNamesFileExt = @"strings";


@interface MGSClassicFragariaParserFactory ()

@property (strong) NSMutableDictionary *syntaxDefinitions;
@property (nonatomic, strong) NSArray<MGSSyntaxGroup> *syntaxGroupsForParsers;

@end


@implementation MGSClassicFragariaParserFactory {
    NSDictionary<MGSSyntaxGroup, NSString *> *_localizedSyntaxGroupNames;
}


@synthesize syntaxDefinitionNames = _syntaxDefinitionNames;


- (instancetype)init
{
    NSArray *bundles = @[[[self class] bundle], [NSBundle mainBundle]];
    NSArray *paths = @[[[self class] applicationSupportSyntaxDefinitionDirectory]];
    
    NSMutableArray *defsPaths = [NSMutableArray array];
    [defsPaths addObjectsFromArray:[[self class] syntaxDefinitionSearchPathsFromBundles:bundles]];
    [defsPaths addObjectsFromArray:paths];
    NSArray <NSURL *> *defs = [[self class] searchSyntaxDefinitionsInSearchPaths:defsPaths];
    
    NSMutableArray *names = [NSMutableArray array];
    [names addObjectsFromArray:[[self class] searchSyntaxGroupNamesInBundles:bundles]];
    [names addObjectsFromArray:[[self class] searchSyntaxGroupNamesInSearchPaths:paths]];
    
    return [self initWithSyntaxDefinitionFiles:defs syntaxGroupNameFiles:names];
}


- (instancetype)initWithSyntaxDefinitionsInBundles:(NSArray <NSBundle *> *)bundles
{
    NSArray <NSURL *> *defssp = [[self class] syntaxDefinitionSearchPathsFromBundles:bundles];
    NSArray <NSURL *> *defs = [[self class] searchSyntaxDefinitionsInSearchPaths:defssp];
    NSArray <NSBundle *> *namesBundles = [@[[[self class] bundle]] arrayByAddingObjectsFromArray:bundles];
    NSArray <NSURL *> *names = [[self class] searchSyntaxGroupNamesInBundles:namesBundles];
    return [self initWithSyntaxDefinitionFiles:defs syntaxGroupNameFiles:names];
}


- (instancetype)initWithSyntaxDefinitionDirectories:(NSArray <NSURL *> *)searchPaths
{
    NSArray <NSURL *> *defs = [[self class] searchSyntaxDefinitionsInSearchPaths:searchPaths];
    NSArray <NSURL *> *baseNames = [[self class] searchSyntaxGroupNamesInBundles:@[[[self class] bundle]]];
    NSArray <NSURL *> *names = [[self class] searchSyntaxGroupNamesInSearchPaths:searchPaths];
    return [self initWithSyntaxDefinitionFiles:defs syntaxGroupNameFiles:[baseNames arrayByAddingObjectsFromArray:names]];
}


- (instancetype)initWithSyntaxDefinitionFiles:(NSArray <NSURL *> *)f syntaxGroupNameFiles:(NSArray <NSURL *> *)strf
{
    self = [super init];
    [self loadSyntaxDefinitionsFromFiles:f];
    [self loadSyntaxGroupNamesFromFiles:strf];
    return self;
}


- (void)loadSyntaxDefinitionsFromFiles:(NSArray <NSURL *> *)syntaxDefFiles
{
    NSMutableSet<MGSSyntaxGroup> *syntaxGroupsLoaded = [NSMutableSet set];
    
    //build a dictionary of definitions keyed by lowercase definition name
    self.syntaxDefinitions = [NSMutableDictionary dictionary];
    NSMutableArray *definitionNames = [NSMutableArray array];
    
    for (NSURL *file in syntaxDefFiles) {
        NSDictionary *root = [NSDictionary dictionaryWithContentsOfURL:file];
        if (!root) {
            NSLog(@"Syntax definition file %@ cannot be loaded; not a dictionary root plist file", file);
            continue;
        }
        
        NSString *name = [root objectForKey:@"name"];
        if (!name)
            name = [[file URLByDeletingPathExtension] lastPathComponent];
        NSString *namek = [name lowercaseString];
        NSDictionary *clashingsyntax = [self.syntaxDefinitions objectForKey:namek];
        if (clashingsyntax) {
            NSURL *clashingfile = [clashingsyntax objectForKey:@"file"];
            NSLog(@"Ignoring syntax definition file %@ as it defines language %@ already loaded"
                "from file %@", file, name, clashingfile);
            continue;
        }
        
        NSArray *extensionsList;
        NSString *extensions = [root objectForKey:@"extensions"];
        if (extensions) {
            NSMutableString *extensionsString = [NSMutableString stringWithString:extensions];
            [extensionsString replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [extensionsString length])];
            extensionsList = [extensionsString componentsSeparatedByString:@" "];
        } else {
            extensionsList = @[];
        }
        
        MGSClassicFragariaSyntaxDefinition *syndef = [[MGSClassicFragariaSyntaxDefinition alloc] initFromSyntaxDictionary:root name:name];
        if (!syndef) {
            NSLog(@"Syntax definition file %@ cannot be loaded; invalid format", file);
            continue;
        }
        
        NSDictionary *syntaxDefinition = @{
            @"name": name,
            @"file": file,
            @"extensions": extensionsList,
            @"syntaxDefinition": syndef};
        
        // key is lowercase name
        [self.syntaxDefinitions setObject:syntaxDefinition forKey:namek];
        [definitionNames addObject:name];
        
        [syntaxGroupsLoaded addObjectsFromArray:[syndef usedSyntaxGroups]];
    }
    
    _syntaxDefinitionNames = [definitionNames copy];
    _syntaxGroupsForParsers = [syntaxGroupsLoaded allObjects];
}


- (void)loadSyntaxGroupNamesFromFiles:(NSArray <NSURL *> *)groupNamesFiles
{
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    
    for (NSURL *fn in groupNamesFiles) {
        NSDictionary *tmp = [NSDictionary dictionaryWithContentsOfURL:fn];
        if (tmp)
            [res addEntriesFromDictionary:tmp];
    }
    
    _localizedSyntaxGroupNames = [res copy];
}


#pragma mark - Utility Methods & File Locators


+ (NSBundle *)bundle
{
    NSBundle *frameworkBundle = [NSBundle bundleForClass:self];
    return frameworkBundle;
}


+ (NSURL *)applicationSupportSyntaxDefinitionDirectory
{
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSURL *appSupport = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    appSupport = [appSupport URLByAppendingPathComponent:appName];
    appSupport = [appSupport URLByAppendingPathComponent:KMGSSyntaxDefinitionsFolder];
    return appSupport;
}


+ (NSArray <NSURL *> *)syntaxDefinitionSearchPathsFromBundles:(NSArray <NSBundle *> *)bundles
{
    NSMutableArray *searchPaths = [NSMutableArray array];
    
    for (NSBundle *bundle in bundles) {
        NSURL *fwkResources = [[bundle resourceURL] URLByAppendingPathComponent:KMGSSyntaxDefinitionsFolder];
        if (fwkResources)
            [searchPaths addObject:fwkResources];
    }

    return [searchPaths copy];
}


+ (NSArray <NSURL *> *)searchSyntaxDefinitionsInSearchPaths:(NSArray <NSURL *> *)searchPaths
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray <NSURL *> *res = [NSMutableArray array];
    
    for (NSURL *path in searchPaths) {
        NSURL *realPath = [path URLByResolvingSymlinksInPath];
        NSDirectoryEnumerator <NSURL *> *de = [fm enumeratorAtURL:realPath includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
        NSURL *f;
        while ((f = de.nextObject)) {
            NSNumber *isdir;
            if (![f getResourceValue:&isdir forKey:NSURLIsDirectoryKey error:nil])
                continue;
            if (isdir.boolValue)
                continue;
            if (![[[f pathExtension] lowercaseString] isEqual:KMGSSyntaxDictionaryExt])
                continue;
            [res addObject:f];
        }
    }
    return [res copy];
}


+ (NSArray <NSURL *> *)searchSyntaxGroupNamesInBundles:(NSArray <NSBundle *> *)bundles
{
    NSMutableArray *files = [NSMutableArray array];
    
    for (NSBundle *bundle in bundles) {
        NSURL *fn = [bundle URLForResource:KMGSSyntaxGroupNamesFileName withExtension:KMGSSyntaxGroupNamesFileExt];
        if (fn)
            [files addObject:fn];
    }
    
    return [files copy];
}


+ (NSArray <NSURL *> *)searchSyntaxGroupNamesInSearchPaths:(NSArray <NSURL *> *)searchPaths
{
    NSMutableArray *files = [NSMutableArray array];
    
    for (NSURL *dirn in searchPaths) {
        NSURL *fn = [dirn URLByAppendingPathComponent:KMGSSyntaxGroupNamesFileName];
        fn = [fn URLByAppendingPathExtension:KMGSSyntaxGroupNamesFileExt];
        [files addObject:fn];
    }
    
    return [files copy];
}


#pragma mark - Parser Factory Methods


/*
 * - syntaxDefinitionWithName:
 */
- (NSDictionary *)syntaxDefinitionWithName:(NSString *)name
{
    // key is lowercase name
    return [self.syntaxDefinitions objectForKey:[name lowercaseString]];
}


/*
 * - syntaxDefinitionNameWithExtension
 */
- (NSArray<NSString *> *)syntaxDefinitionNamesWithExtension:(NSString *)extension
{
    NSString *name = nil;
    NSDictionary *definition = [self syntaxDefinitionWithExtension:extension];
    if (definition) {
        name = [definition objectForKey:@"name"];
    }
    
    return name ? @[name] : @[];
}


- (NSArray<NSString *> *)extensionsForSyntaxDefinitionName:(NSString *)sdname
{
    NSArray *extList = [[self syntaxDefinitionWithName:sdname] objectForKey:@"extensions"];
    if (!extList)
        return @[];
    return extList;
}


/*
 * - syntaxDefinitionWithExtension
 */
- (NSDictionary *)syntaxDefinitionWithExtension:(NSString *)extension
{
    NSDictionary *definition = nil;
    
    extension = [extension lowercaseString];
    
    for (id item in self.syntaxDefinitions) {
        NSArray *extList = [self extensionsForSyntaxDefinitionName:item];
        
        if ([extList containsObject:extension]) {
            definition = self.syntaxDefinitions[item];
            break;
        }
    }
    
    return definition;
}


- (NSDictionary *)syntaxDefinitionWithUTI:(NSString *)uti
{
    NSArray <NSString *> *exts = CFBridgingRelease(UTTypeCopyAllTagsWithClass((__bridge CFStringRef)uti, kUTTagClassFilenameExtension));
    
    for (NSString *ext in exts) {
        NSDictionary *def = [self syntaxDefinitionWithExtension:ext];
        if (def)
            return def;
    }
    return nil;
}


- (NSArray<NSString *> *)syntaxDefinitionNamesWithUTI:(NSString *)uti
{
    NSString *name = nil;
    NSDictionary *definition = [self syntaxDefinitionWithUTI:uti];
    if (definition) {
        name = [definition objectForKey:@"name"];
    }
    
    return name ? @[name] : @[];
}


/*
 * - guessSyntaxDefinitionExtensionFromFirstLine:
 */
- (NSArray<NSString *> *)guessSyntaxDefinitionNamesFromFirstLine:(NSString *)firstLine
{
    NSString *returnString = nil;
    NSRange firstLineRange = NSMakeRange(0, [firstLine length]);
    if ([firstLine rangeOfString:@"perl" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"pl";
    } else if ([firstLine rangeOfString:@"wish" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"tcl";
    } else if ([firstLine rangeOfString:@"sh" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"sh";
    } else if ([firstLine rangeOfString:@"php" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"php";
    } else if ([firstLine rangeOfString:@"python" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"py";
    } else if ([firstLine rangeOfString:@"awk" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"awk";
    } else if ([firstLine rangeOfString:@"xml" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"xml";
    } else if ([firstLine rangeOfString:@"ruby" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"rb";
    } else if ([firstLine rangeOfString:@"%!ps" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"ps";
    } else if ([firstLine rangeOfString:@"%pdf" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
        returnString = @"pdf";
    }
    
    if (returnString)
        return [self syntaxDefinitionNamesWithExtension:returnString];
    return @[];
}


- (MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)name
{
    NSDictionary *definition = [self syntaxDefinitionWithName:name];
    MGSClassicFragariaSyntaxDefinition *syntaxDef = [definition objectForKey:@"syntaxDefinition"];
    return [[MGSClassicFragariaSyntaxParser alloc] initWithSyntaxDefinition:syntaxDef];
}


- (NSString *)localizedDisplayNameForSyntaxGroup:(MGSSyntaxGroup)syntaxGroup
{
    NSString *res = [_localizedSyntaxGroupNames objectForKey:syntaxGroup];
    return res ?: syntaxGroup;
}


@end
