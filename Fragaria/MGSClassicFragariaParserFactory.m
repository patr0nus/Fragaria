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


- (void)insertSyntaxDefinitions
{
    NSArray <NSURL *> *syntaxDefFiles = [self searchSyntaxDefinitions];
    
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
        NSString *extensions = [root objectForKey:@"extensions"] ?: @"";
        MGSClassicFragariaSyntaxDefinition *syndef = [[MGSClassicFragariaSyntaxDefinition alloc] initFromSyntaxDictionary:root name:name];
        if (!syndef) {
            NSLog(@"Syntax definition file %@ cannot be loaded; invalid format", file);
            continue;
        }
        
        NSDictionary *syntaxDefinition = @{
            @"name": name,
            @"file": file,
            @"extensions": extensions,
            @"syntaxDefinition": syndef};
        
        // key is lowercase name
        [self.syntaxDefinitions setObject:syntaxDefinition forKey:[name lowercaseString]];
        [definitionNames addObject:name];
    }
    
    _syntaxDefinitionNames = [definitionNames copy];
}


- (NSArray <NSURL *> *)syntaxDefinitionSearchPaths
{
    NSMutableArray *searchPaths = [NSMutableArray array];
    
    NSURL *fwkResources = [[[self bundle] resourceURL] URLByAppendingPathComponent:KMGSSyntaxDefinitionsFolder];
    if (fwkResources)
        [searchPaths addObject:fwkResources];
    
    NSURL *appResources = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:KMGSSyntaxDefinitionsFolder];
    if (appResources)
        [searchPaths addObject:appResources];
    
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSURL *appSupport = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    appSupport = [appSupport URLByAppendingPathComponent:appName];
    appSupport = [appSupport URLByAppendingPathComponent:KMGSSyntaxDefinitionsFolder];
    if (appSupport)
        [searchPaths addObject:appSupport];
    
    return [searchPaths copy];
}


- (NSArray <NSURL *> *)searchSyntaxDefinitions
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray <NSURL *> *res = [NSMutableArray array];
    NSArray <NSURL *> *searchPaths = [self syntaxDefinitionSearchPaths];
    
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


- (MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)name
{
    if (!name) {
        name = [[self class] standardSyntaxDefinitionName];
    }
    
    NSDictionary *definition = [self syntaxDefinitionWithName:name];
    MGSClassicFragariaSyntaxDefinition *syntaxDef = [definition objectForKey:@"syntaxDefinition"];
    return [[MGSClassicFragariaSyntaxParser alloc] initWithSyntaxDefinition:syntaxDef];
}


- (NSArray<SMLSyntaxGroup> *)syntaxGroupsForParsers
{
    return @[
        SMLSyntaxGroupNumber,
        SMLSyntaxGroupCommand,
        SMLSyntaxGroupInstruction,
        SMLSyntaxGroupKeyword,
        SMLSyntaxGroupAutoComplete,
        SMLSyntaxGroupVariable,
        SMLSyntaxGroupString,
        SMLSyntaxGroupAttribute,
        SMLSyntaxGroupComment];
}


- (NSString *)localizedDisplayNameForSyntaxGroup:(SMLSyntaxGroup)syntaxGroup
{
    if ([syntaxGroup isEqual:SMLSyntaxGroupNumber])
        return NSLocalizedString(@"Number", @"Localized name of syntax group \"number\"");
    if ([syntaxGroup isEqual:SMLSyntaxGroupCommand])
        return NSLocalizedString(@"Command", @"Localized name of syntax group \"command\"");
    if ([syntaxGroup isEqual:SMLSyntaxGroupInstruction])
        return NSLocalizedString(@"Instruction", @"Localized name of syntax group \"instruction\"");
    if ([syntaxGroup isEqual:SMLSyntaxGroupKeyword])
        return NSLocalizedString(@"Keyword", @"Localized name of syntax group \"keyword\"");
    if ([syntaxGroup isEqual:SMLSyntaxGroupAutoComplete])
        return NSLocalizedString(@"Autocomplete", @"Localized name of syntax group \"autocomplete\"");
    if ([syntaxGroup isEqual:SMLSyntaxGroupVariable])
        return NSLocalizedString(@"Variable", @"Localized name of syntax group \"variable\"");
    if ([syntaxGroup isEqual:SMLSyntaxGroupString])
        return NSLocalizedString(@"String", @"Localized name of syntax group \"string\"");
    if ([syntaxGroup isEqual:SMLSyntaxGroupAttribute])
        return NSLocalizedString(@"Attribute", @"Localized name of syntax group \"attribute\"");
    if ([syntaxGroup isEqual:SMLSyntaxGroupComment])
        return NSLocalizedString(@"Comment", @"Localized name of syntax group \"comment\"");
    return nil;
}


@end
