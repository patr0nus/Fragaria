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


NSString * const KMGSSyntaxDefinitions =  @"SyntaxDefinitions";
NSString * const KMGSSyntaxDefinitionsExt = @"plist";
NSString * const kMGSSyntaxDefinitionsFile = @"SyntaxDefinitions.plist";
NSString * const KMGSSyntaxDictionaryExt = @"plist";
NSString * const KMGSSyntaxDefinitionsFolder = @"Syntax Definitions";


@interface MGSClassicFragariaParserFactory ()

@property (strong) NSMutableDictionary *syntaxDefinitions;

@end


@implementation MGSClassicFragariaParserFactory


@synthesize syntaxDefinitionNames = _syntaxDefinitionNames;


- (id)init
{
    self = [super init];
    
    if (self) {
        [self insertSyntaxDefinitions];
    }
    return self;
}


/*
 * + standardSyntaxDefinitionName
 */
+ (NSString *)standardSyntaxDefinitionName
{
    return @"Standard";
}


/*
 * - insertSyntaxDefinitions
 */
- (void)insertSyntaxDefinitions
{
    // load definitions
    NSMutableArray *syntaxDefinitionsArray = [self loadSyntaxDefinitions];
    
    // add Standard and None definitions
    NSDictionary *standard = @{@"name": [[self class] standardSyntaxDefinitionName],
                               @"file": @"standard",
                               @"extensions": @""};
    NSDictionary *none = @{@"name": @"None",
                           @"file": @"none",
                           @"extensions": @"txt"};
    [syntaxDefinitionsArray insertObject:none atIndex:0];
    [syntaxDefinitionsArray insertObject:standard atIndex:0];
    
    //build a dictionary of definitions keyed by lowercase definition name
    self.syntaxDefinitions = [NSMutableDictionary dictionaryWithCapacity:30];
    NSMutableArray *definitionNames = [NSMutableArray arrayWithCapacity:30];
    
    NSInteger idx = 0;
    for (id item in syntaxDefinitionsArray) {
        
        if ([[item objectForKey:@"extensions"] isKindOfClass:[NSArray class]]) {
            // If extensions is an array instead of a string, i.e. an older version
            continue;
        }
        
        NSString *name = [item objectForKey:@"name"];
        
        id syntaxDefinition = [NSMutableDictionary dictionaryWithCapacity:6];
        [syntaxDefinition setObject:name forKey:@"name"];
        [syntaxDefinition setObject:[item objectForKey:@"file"] forKey:@"file"];
        [syntaxDefinition setObject:[NSNumber numberWithInteger:idx] forKey:@"sortOrder"];
        [syntaxDefinition setObject:[item objectForKey:@"extensions"] forKey:@"extensions"];
        idx++;
        
        // key is lowercase name
        [self.syntaxDefinitions setObject:syntaxDefinition forKey:[name lowercaseString]];
        [definitionNames addObject:name];
    }
    
    _syntaxDefinitionNames = [definitionNames copy];
}


/*
 * - loadSyntaxDefinitions
 */
- (NSMutableArray *)loadSyntaxDefinitions
{
    NSMutableArray *syntaxDefinitionsArray = [NSMutableArray arrayWithCapacity:30];
    
    // load syntax definitions from this bundle
    NSString *path = [[self bundle] pathForResource:KMGSSyntaxDefinitions ofType:KMGSSyntaxDefinitionsExt];
    NSAssert(path, @"framework syntax definitions not found");
    [self addSyntaxDefinitions:syntaxDefinitionsArray path:path];
    
    // load syntax definitions from app bundle
    path = [[NSBundle mainBundle] pathForResource:KMGSSyntaxDefinitions ofType:KMGSSyntaxDefinitionsExt];
    [self addSyntaxDefinitions:syntaxDefinitionsArray path:path];
    
    // load syntax definitions from application support
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    path = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:appName] stringByAppendingPathComponent:kMGSSyntaxDefinitionsFile];
    [self addSyntaxDefinitions:syntaxDefinitionsArray path:path];
    
    return syntaxDefinitionsArray;
}


#pragma mark - Utilities


- (NSBundle *)bundle
{
    NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];

    return frameworkBundle;
}


#pragma mark - Parser Factory Methods


/*
 *- standardSyntaxDefinition
 */
- (NSDictionary *)standardSyntaxDefinition
{
    // key is lowercase name
    NSString *name = [[self class] standardSyntaxDefinitionName];
    NSDictionary *definition = [self.syntaxDefinitions objectForKey:[name lowercaseString]];
    NSAssert(definition, @"standard syntax definition not found");
    return definition;
}


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


/*
 * - syntaxDefinitionWithExtension
 */
- (NSDictionary *)syntaxDefinitionWithExtension:(NSString *)extension
{
    NSDictionary *definition = nil;
    
    extension = [extension lowercaseString];
    
    for (id item in self.syntaxDefinitions) {
        NSString *extensions = [self.syntaxDefinitions[item] valueForKey:@"extensions"];
        
        if (!extensions || [extensions isEqualToString:@""]) {
            continue;
        }
        
        NSMutableString *extensionsString = [NSMutableString stringWithString:extensions];
        [extensionsString replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [extensionsString length])];
        if ([[extensionsString componentsSeparatedByString:@" "] containsObject:extension]) {
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


/*
 * - syntaxDictionaryWithName:
 */
- (NSDictionary *)syntaxDictionaryWithName:(NSString *)name
{
    if (!name) {
        name = [[self class] standardSyntaxDefinitionName];
    }
    
    NSDictionary *definition = [self syntaxDefinitionWithName:name];
    
    for (NSInteger i = 0; i <= 1; i++) {
        NSString *fileName = [definition objectForKey:@"file"];
        
        // load dictionary from this bundle
        NSDictionary *syntaxDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[self bundle] pathForResource:fileName ofType:KMGSSyntaxDefinitionsExt inDirectory:KMGSSyntaxDefinitionsFolder]];
        if (syntaxDictionary) return syntaxDictionary;
        
        // load dictionary from main bundle
        syntaxDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:KMGSSyntaxDefinitionsExt inDirectory:KMGSSyntaxDefinitionsFolder]];
        if (syntaxDictionary) return syntaxDictionary;
        
        // load from application support
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        NSString *path = [[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:appName] stringByAppendingPathComponent:fileName] stringByAppendingString:KMGSSyntaxDictionaryExt];
        syntaxDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
        if (syntaxDictionary) return syntaxDictionary;
        
        // no dictionary found so use standard definition
        definition = [self standardSyntaxDefinition];
    }
    
    return nil;
}


/*
 * - addSyntaxDefinitions:path:
 */
- (void)addSyntaxDefinitions:(NSMutableArray *)definitions path:(NSString *)path
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == YES) {
        [definitions addObjectsFromArray:[[NSArray alloc] initWithContentsOfFile:path]];
    }
    
}


- (MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)syndef
{
    NSDictionary *syntaxDict;
    MGSClassicFragariaSyntaxDefinition *syntaxDef;
    
    syntaxDict = [self syntaxDictionaryWithName:syndef];
    syntaxDef = [[MGSClassicFragariaSyntaxDefinition alloc] initFromSyntaxDictionary:syntaxDict name:syndef];
    return [[MGSClassicFragariaSyntaxParser alloc] initWithSyntaxDefinition:syntaxDef];
}


@end
