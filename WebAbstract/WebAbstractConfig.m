//
//  WebAbstractConfig.m
//  Gymclass
//
//  Created by Eric Colton on 2/9/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "WebAbstractConfig.h"
#import "HttpPostValue.h"

#define DEFAULT_TIMEOUT_SECONDS 60

static NSSet *validUrlProtocols;
static NSSet *validHttpMethods;
static NSSet *validDateComponents;
static NSDictionary *validHppleRegExs;
static NSRegularExpression *defaultPatternRegEx;

@interface WebAbstractConfig()
{
    NSDictionary *_config;
}

-(void)setConfigStruct:(NSDictionary *)aConfigStruct;

+(NSDictionary *)validateAndFormatConfig:(id)aStruct;
+(NSDictionary *)validateAndFormatSourceStruct:(NSDictionary *)aStruct     withDefaults:(NSDictionary *)aDefaults forPathDesc:(NSString *)aPathDesc;
+(NSDictionary *)validateAndFormatOutputStruct:(NSDictionary *)aStruct     withDefaults:(NSDictionary *)aDefaults forPathDesc:(NSString *)aPathDesc;

+(NSDictionary *)validateAndFormatParseStruct:(NSDictionary *)aParseStruct
                                 withDefaults:(NSDictionary *)aDefaults
                               mustReturnDict:(BOOL)aMustReturnDict
                                  forPathDesc:(NSString *)aPathDesc;

+(NSString *)removeSquareBrackets:(NSString *)aString;
+(NSString *)removeCurlyBrackets:(NSString *)aString;
+(NSString *)removeSingleQuotes:(NSString *)aString;
+(NSString *)removeSurroundingChars:(NSString *)aChars fromString:(NSString *)aString;

+(void)validateDict:(NSDictionary *)aStruct
    forRequiredKeys:(NSSet *)aRequiredKeys
       forValidKeys:(NSSet *)aValidKeys
        forPathDesc:(NSString *)aPathDesc;

@end

@implementation WebAbstractConfig

+(void)initialize
{
    validUrlProtocols = [NSSet setWithObjects:@"http", @"https", nil];
    validHttpMethods = [NSSet setWithObjects:@"GET", @"POST", nil];
    
    validDateComponents = [NSSet setWithObjects:@"era", @"year", @"twoDigitYear", @"month", @"day", @"hour", @"minute", @"second", @"week", @"weekday", @"weekdayOrdinal", @"quarter", @"weekOfMonth", @"weekOfYear", @"yearForWeekOfYear", nil];
    
    NSRegularExpression *textRegEx = [NSRegularExpression regularExpressionWithPattern:@"^text$"
                                                                               options:0
                                                                                 error:NULL
                                      ];
    
    NSRegularExpression *contentRegEx = [NSRegularExpression regularExpressionWithPattern:@"^content$"
                                                                                  options:0
                                                                                    error:NULL
                                         ];
    
    NSRegularExpression *attrRegEx = [NSRegularExpression regularExpressionWithPattern:@"^@(\\w+)$"
                                                                               options:0
                                                                                 error:NULL
                                      ];
    NSRegularExpression *childRegEx = [NSRegularExpression regularExpressionWithPattern:@"^child(?:\\{(\\w+)\\})?\\s*(?:\\[([1-9]\\d*)\\])?$"
                                                                                options:0
                                                                                  error:NULL
                                       ];
    
    validHppleRegExs = @{ textRegEx    : @"TEXT"
                         ,contentRegEx : @"CONTENT"
                         ,attrRegEx    : @"ATTR"
                         ,childRegEx   : @"CHILD"
                        };
    
    defaultPatternRegEx = [NSRegularExpression regularExpressionWithPattern:@"^\\s*(.*?)\\s*$"
                                                                    options:NSRegularExpressionDotMatchesLineSeparators
                                                                      error:NULL
                           ];
}

////
#pragma mark class methods (public)
////
+(NSString *)removeSquareBrackets:(NSString *)aString
{
    return [WebAbstractConfig removeSurroundingChars:(NSString *)@"[]" fromString:(NSString *)aString];
}

+(NSString *)removeCurlyBrackets:(NSString *)aString
{
    return [WebAbstractConfig removeSurroundingChars:(NSString *)@"{}" fromString:(NSString *)aString];
}

+(NSString *)removeSingleQuotes:(NSString *)aString
{
    return [WebAbstractConfig removeSurroundingChars:(NSString *)@"''" fromString:(NSString *)aString];
}

+(NSString *)removeSurroundingChars:(NSString *)aSurroundingChars fromString:(NSString *)aString
{
    NSUInteger surLength = aSurroundingChars.length;

    if ( ( surLength % 2 ) != 0 )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"length of 'surroundingChars' must be of an even length"
         ];
   
    NSUInteger length = aString.length;
    NSUInteger surHalfLength = surLength / 2;

    if ( !aString ) {
        return nil;
    } else if ( length < 3 ) {
        return aString.copy;
    }
    
    NSString *startChars  = [aSurroundingChars substringWithRange:NSMakeRange(0, surHalfLength)];
    NSString *startString = [aString substringWithRange:NSMakeRange(0, surHalfLength)];
    
    NSString *endChars = [aSurroundingChars substringWithRange:NSMakeRange(surLength - surHalfLength, surHalfLength)];
    NSString *endString = [aString substringWithRange:NSMakeRange(length - surHalfLength, surHalfLength)];
    
    if ( [startChars isEqualToString:startString] && [endChars isEqualToString:endString] ) {
        return [aString substringWithRange:NSMakeRange(surHalfLength, length - surLength)];
    } else {
        return aString.copy;
    }
}

////
#pragma mark init methods (public)
////
-(id)initWithStruct:(NSDictionary *)aStruct
{
    self = [super init];
    if ( self ) {
        [self setConfigStruct:aStruct];
    }
    
    return self;
}

-(id)initWithURL:(NSURL *)aUrl
{
    self = [super init];
    if ( self ) {
        self.url = aUrl;
        self.cachePolicy = NSURLRequestUseProtocolCachePolicy;
        self.timeoutInterval = DEFAULT_TIMEOUT_SECONDS;
    }
    
    return self;
}

-(id)initWithBundledPlist:(NSString *)aPlistName
{
    NSString *configPath = [[NSBundle mainBundle] pathForResource:aPlistName ofType:@"plist"];
    
    if ( !configPath )
        [NSException raise:kExceptionWebAbstractConfigNotFound
                    format:@"specified plist '%@' not found", aPlistName
         ];
    
    NSError *error;
    NSData *configData = [NSData dataWithContentsOfFile:configPath
                                                options:0
                                                  error:&error
                          ];
    if ( error )
        [NSException raise:kExceptionWebAbstractConfigBundle
                    format:@"could not read bundled plist '%@' for WebAbstractConfig.  Error: %@", configPath, [error localizedDescription]
         ];

    NSDictionary *configStruct = [NSPropertyListSerialization propertyListWithData:configData
                                                                           options:NSPropertyListImmutable
                                                                            format:nil
                                                                             error:&error
                                  ];
    
    if ( error )
        [NSException raise:kExceptionWebAbstractConfigBundle
                    format:@"could not parse bundled plist '%@' for WebAbstractConfig.  Error: %@", configPath, [error localizedDescription]
         ];
    
    return [self initWithStruct:configStruct];
}

////
#pragma mark accessor methods (public)
////
-(void)setConfigStruct:(NSDictionary *)aConfigStruct
{
    if ( aConfigStruct != _configStruct ) {
        _config = [WebAbstractConfig validateAndFormatConfig:aConfigStruct];
        _configStruct = aConfigStruct;
    }
}

////
#pragma mark instance methods (public)
////
-(BOOL)refreshFromWeb:(NSError *__autoreleasing *)aError
{
    if ( !_url )
        [NSException raise:kExceptionWebAbstractConfigIllegalOp
                    format:@"can only call refreshFromWeb: on a WebAbstractConfig object that was initalized with a URL"
         ];

    //note that all
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:_url
                                              cachePolicy:self.cachePolicy
                                          timeoutInterval:self.timeoutInterval
                         ];
    
    NSURLResponse *response;
    NSError *error;
    NSData *webData = [NSURLConnection sendSynchronousRequest:req
                                            returningResponse:&response
                                                        error:&error
                       ];
    
    if ( error ) {
        _configStruct = nil;
        _config = nil;
        if ( aError ) *aError = error;
        return YES;
    }

    NSDictionary *newConfigStruct = [NSPropertyListSerialization propertyListWithData:webData
                                                                              options:NSPropertyListImmutable
                                                                               format:NULL
                                                                                error:&error
                                     ];
    
    if ( error )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"could not parse plist for WebAbstractConfig from URL: '%@'.  Error: %@", _url, [error localizedDescription]
         ];
    
    self.configStruct = newConfigStruct;
    
    return NO;
}

-(NSDictionary *)fetchConfigForOperation:(NSString *)aOperation forSourceTag:(NSString *)aSourceTag
{
    return [[[_config objectForKey:aOperation] objectForKey:@"source"] objectForKey:aSourceTag];
}

-(NSDictionary *)fetchConfigForOperation:(NSString *)aOperation forOutputTag:(NSString *)aOutputTag
{
    return [[[_config objectForKey:aOperation] objectForKey:@"output"] objectForKey:aOutputTag];
}

////
#pragma mark class methods (private)
////
+(NSDictionary *)validateAndFormatConfig:(id)aConfigStruct
{
    if ( ![aConfigStruct isKindOfClass:[NSDictionary class]] )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"root structure is not a an NSDictionary"
         ];
    
    NSMutableDictionary *mutableConfigStruct = [[NSMutableDictionary alloc] init];
    
    id configDict = [aConfigStruct objectForKey:@"_config"];
    if ( configDict ) {
        
        if ( ![configDict isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"value for top level key '_config' must be an NSDictionary"
             ];
            
        static NSSet *validKeys, *requiredKeys;
        if ( !validKeys ) {
                    
            NSArray *required = @[];
            NSArray *valid    = @[@"defaults"];
                    
            requiredKeys = [NSSet setWithArray:required];
            validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
        }
            
        [self validateDict:configDict forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:@"_config"];
            
        for ( id configDictKey in [configDict allKeys] ) {
                
            if ( ![configDictKey isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"top level key '%@' in '_config' must be an NSString", configDictKey
                 ];
                
            id configDictVal = [configDict objectForKey:configDictKey];

            if ( [configDictKey isEqualToString:@"defaults"] ) {
                    
                if ( ![configDictVal isKindOfClass:[NSDictionary class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"value for key 'defaults' in '_config' must be an NSDictionary"
                     ];

                static NSSet *validKeys, *requiredKeys;
                if ( !validKeys ) {
                            
                    NSArray *required = @[];
                    NSArray *valid    = @[@"urlProtocol", @"urlHttpMethod", @"patternsCaseInsensitive"];
                            
                    requiredKeys = [NSSet setWithArray:required];
                    validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
                }
                    
                [self validateDict:configDictVal forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:@"_config.defaults"];
                    
                for ( id defaultsKey in [configDictVal allKeys] ) {
                        
                    id defaultsVal = [configDictVal objectForKey:defaultsKey];
                        
                    NSString *pathDesc = [NSString stringWithFormat:@"_config.defaults.%@", defaultsKey];
                        
                    if ( [defaultsKey isEqualToString:@"urlProtocol"] ) {

                        if ( ![defaultsVal isKindOfClass:[NSString class]] )
                            [NSException raise:kExceptionWebAbstractConfigValidate
                                        format:@"value for key 'urlProtocol' in '%@' must be an NSString", pathDesc
                             ];
                            
                        if ( ![validUrlProtocols containsObject:defaultsVal] )
                            [NSException raise:kExceptionWebAbstractConfigValidate
                                        format:@"value for key 'urlProtocol' in '%@' must be a valid protocol", pathDesc
                             ];
                        
                    } else if ( [defaultsKey isEqualToString:@"patternsCaseInsensitive"] ) {
                        
                        if ( ![defaultsVal isKindOfClass:[NSNumber class]] )
                            [NSException raise:kExceptionWebAbstractConfigValidate
                                        format:@"value for key 'patternsCaseInsensitive' in '%@' must be a Boolean NSNumber", pathDesc
                             ];
                    }
                }
            }
        }
    }
    
    for ( id rawOperationKey in [aConfigStruct allKeys] ) {
        
        if ( ![rawOperationKey isKindOfClass:[NSString class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"operation '%@' of root structure must be an NSString", rawOperationKey
             ];
        
        if ( [rawOperationKey isEqualToString:@"_config"] ) continue;
        
        // Bypass "commented out" configurations
        if ( [[rawOperationKey substringToIndex:2] isEqualToString:@"//"] ) continue;

        id operationVal = [aConfigStruct objectForKey:rawOperationKey];
        
        // Operation Keys may have double-square-brackets
        NSString *operationKey = [self removeSquareBrackets:[self removeSquareBrackets:rawOperationKey]];
        
        if ( ![operationVal isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"value for operation '%@' must be an NSDictionary", operationKey
             ];
        
        static NSSet *validKeys, *requiredKeys;
        if ( !validKeys ) {
            
            NSArray *required = @[];
            NSArray *valid    = @[@"source", @"output"];
            
            requiredKeys = [NSSet setWithArray:required];
            validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
        }
        
        [self validateDict:operationVal forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:operationKey];

        NSMutableDictionary *mutableOperationVal = [[NSMutableDictionary alloc] init];
            
        id source = [operationVal objectForKey:@"source"];
        if ( source ) {
                
            if ( ![source isKindOfClass:[NSDictionary class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key 'source' for operation '%@' must be an NSDictionary", operationKey
                 ];
                
            NSMutableDictionary *mutableSource = [[NSMutableDictionary alloc] init];
                
            for ( id rawSourceTag in [source allKeys] ) {
                
                if ( ![rawSourceTag isKindOfClass:[NSString class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"sourceTag '%@' for opeation '%@' must be an NSString", rawSourceTag, operationKey
                     ];

                // Bypass "commented out" configurations
                if ( [[rawSourceTag substringToIndex:2] isEqualToString:@"//"] ) continue;
                
                id sourceVal = [source objectForKey:rawSourceTag];
                NSString *sourceTag = [self removeSquareBrackets:rawSourceTag];
                    
                if ( ![sourceVal isKindOfClass:[NSDictionary class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"value for sourceTag '%@' for operation '%@' must be an NSDictionary", sourceTag, operationKey
                     ];
        
                sourceVal = [self validateAndFormatSourceStruct:sourceVal
                                                   withDefaults:[configDict objectForKey:@"defaults"]
                                                    forPathDesc:[NSString stringWithFormat:@"%@.source.%@", operationKey, sourceTag]
                             ];
                    
                [mutableSource setObject:sourceVal forKey:sourceTag];
            }
                
            [mutableOperationVal setObject:[NSDictionary dictionaryWithDictionary:mutableSource] forKey:@"source"];
        }
                    
        id output = [operationVal objectForKey:@"output"];
        if ( output ) {
                
            if ( ![output isKindOfClass:[NSDictionary class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key 'output' for operation '%@' must be an NSDictionary", operationKey
                 ];
                
            NSMutableDictionary *mutableOutput = [[NSMutableDictionary alloc] init];
                
            for ( id rawOutputTag in [output allKeys] ) {
                        
                if ( ![rawOutputTag isKindOfClass:[NSString class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"value for outputTag '%@' for operation '%@' must be an NSString", rawOutputTag, operationKey
                     ];
                
                // Bypass "commented out" configurations
                if ( [[rawOutputTag substringToIndex:2] isEqualToString:@"//"] ) continue;
                
                NSString *outputTag = [self removeSquareBrackets:rawOutputTag];
                
                id outputVal = [output objectForKey:rawOutputTag];

                if ( ![outputVal isKindOfClass:[NSDictionary class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"outputTag '%@' for '%@' must be an NSDictionary", outputTag, operationKey
                     ];
                
                outputVal = [self validateAndFormatOutputStruct:outputVal
                                                   withDefaults:[configDict objectForKey:@"defaults"]
                                                    forPathDesc:[NSString stringWithFormat:@"%@.output.%@", operationKey, outputTag]
                             ];
                    
                [mutableOutput setObject:outputVal forKey:outputTag];
            }
                
            [mutableOperationVal setObject:[NSDictionary dictionaryWithDictionary:mutableOutput] forKey:@"output"];
        }
            
        [mutableConfigStruct setObject:[NSDictionary dictionaryWithDictionary:mutableOperationVal] forKey:operationKey];
    }
    
    return [NSDictionary dictionaryWithDictionary:mutableConfigStruct];
}

+(NSDictionary *)validateAndFormatSourceStruct:(NSDictionary *)aSourceStruct
                                  withDefaults:(NSDictionary *)aDefaults
                                   forPathDesc:(NSString *)aPathDesc
{
    static NSSet *validKeys, *requiredKeys;
    if ( !validKeys ) {
        
        NSArray *required = @[@"url"];
        NSArray *valid    = @[];
        
        requiredKeys = [NSSet setWithArray:required];
        validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
    }
    
    [self validateDict:aSourceStruct forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:aPathDesc];

    NSMutableDictionary *mutableSourceStruct = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *mutableUrl = [[NSMutableDictionary alloc] init];
    
    id url = [aSourceStruct objectForKey:@"url"];
    
    if ( ![url isKindOfClass:[NSDictionary class]] )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"'url' in '%@' must be an NSDictionary", aPathDesc
         ];
        
    NSString *pathDescUrl = [NSString stringWithFormat:@"%@.url", aPathDesc];
    
    static NSSet *validUrlKeys, *requiredUrlKeys;
    if ( !validUrlKeys ) {
        
        NSArray *required = @[@"format"];
        NSArray *valid    = @[@"httpMethod", @"protocol", @"variables", @"postVariables", @"userAgent"];
        
        requiredUrlKeys = [NSSet setWithArray:required];
        validUrlKeys = [requiredUrlKeys setByAddingObjectsFromArray:valid];
    }
    
    [self validateDict:url forRequiredKeys:requiredUrlKeys forValidKeys:validUrlKeys forPathDesc:pathDescUrl];
    
    id format = [url objectForKey:@"format"];
    if ( ![format isKindOfClass:[NSString class]] )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"value for key 'format' in '%@' must be an NSString", pathDescUrl
         ];
    
    [mutableUrl setObject:format forKey:@"format"];

    id httpMethod;
    if ( [url objectForKey:@"httpMethod"] ) {
        httpMethod = [url objectForKey:@"httpMethod"];
    } else if ( [aDefaults objectForKey:@"urlHttpMethod"] ) {
        httpMethod = [aDefaults objectForKey:@"urlHttpMethod"];
    }

    if ( httpMethod ) {
                
        if ( ![httpMethod isKindOfClass:[NSString class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"value for key 'httpMethod' in '%@' must be an NSString", pathDescUrl
             ];
            
        if ( ![validHttpMethods containsObject:httpMethod] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"value '%@' in '%@' is not a valid HTTP method", httpMethod, pathDescUrl
             ];
        
        [mutableUrl setObject:httpMethod forKey:@"httpMethod"];
    }
    
    id protocol;
    if ( [url objectForKey:@"protocol"] ) {
        protocol = [url objectForKey:@"protocol"];
    } else if ( [aDefaults objectForKey:@"urlProtocol"] ) {
        protocol = [aDefaults objectForKey:@"urlProtocol"];
    }
    
    if ( protocol ) {
            
        if ( ![protocol isKindOfClass:[NSString class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'protocol' in '%@' must be an NSString", pathDescUrl
             ];

        if ( ![validUrlProtocols containsObject:protocol] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"value '%@' for key 'protocol' in '%@' not a valid protocol", protocol, pathDescUrl
             ];

        [mutableUrl setObject:protocol forKey:@"protocol"];
    }
    
    id variables = [url objectForKey:@"variables"];
    if ( variables ) {
                
        if ( ![variables isKindOfClass:[NSArray class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'variables' in '%@' must be an NSArray", pathDescUrl
             ];

        for ( int i = 0; i < [variables count]; i++ ) {

            NSString *pathDesc2 = [NSString stringWithFormat:@"%@.variables[%d]", pathDescUrl, i];
                
            id variableVal = [variables objectAtIndex:i];
                
            if ( [variableVal isKindOfClass:[NSDictionary class]] ) {

                id type = [variableVal objectForKey:@"type"];
                    
                if ( ![type isKindOfClass:[NSString class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"value for key 'type' in '%@' must be an NSString", pathDesc2
                     ];

                if ( [type isEqualToString:@"date"] ) {
                            
                    static NSSet *validKeys, *requiredKeys;
                    if ( !validKeys ) {
                                
                        NSArray *required = @[@"type", @"dateFormat", @"dateVariables"];
                        NSArray *valid    = @[@"useDateFromVariable", @"dayOffset", @"secondOffset"];

                        requiredKeys = [NSSet setWithArray:required];
                        validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
                    }
                            
                    [self validateDict:variableVal forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:pathDesc2];
                    
                    id dayOffset = [variableVal objectForKey:@"dayOffset"];
                    if ( dayOffset ) {
                        if ( ![dayOffset isKindOfClass:[NSNumber class]] )
                            [NSException raise:kExceptionWebAbstractConfigValidate
                                        format:@"if specified, value for key 'dayOffset' in date-dictionary '%@' must be an NSNumber", pathDesc2
                            ];
                    }

                    id secondOffset = [variableVal objectForKey:@"secondOffset"];
                    if ( secondOffset ) {
                        if ( ![secondOffset isKindOfClass:[NSNumber class]] )
                            [NSException raise:kExceptionWebAbstractConfigValidate
                                        format:@"if specified, value for key 'secondOffset' in date-dictionary in '%@' must be an NSNumber", pathDesc2
                            ];
                    }
                            
                    id dateFormat = [variableVal objectForKey:@"dateFormat"];
                    if ( ![dateFormat isKindOfClass:[NSString class]] )
                        [NSException raise:kExceptionWebAbstractConfigValidate
                                    format:@"value for key 'dateFormat' of date-dictionary in '%@' must be an NSString", pathDesc2
                         ];
                    
                    id useDateFromVariable = [variableVal objectForKey:@"useDateFromVariable"];
                    if ( useDateFromVariable ) {
                        if ( ![useDateFromVariable isKindOfClass:[NSString class]] )
                            [NSException raise:kExceptionWebAbstractConfigValidate
                                        format:@"if specified, value for key 'useDateFromVariable' in date-dictionary '%@' must be an NSString", pathDesc2
                             ];
                    }
                    
                    id dateVariables = [variableVal objectForKey:@"dateVariables"];
                    if ( dateVariables ) {
                    
                        if ( ![dateVariables isKindOfClass:[NSArray class]] )
                            [NSException raise:kExceptionWebAbstractConfigValidate
                                        format:@"value for key 'dateVariables' in date-variable dictionary in '%@' must be an NSArray", pathDesc2
                             ];
                                
                        for ( int j = 0; j < [dateVariables count]; j++ ) {
                                
                            NSString *pathDesc3 = [NSString stringWithFormat:@"%@.dateVariables[%d]", pathDesc2, j];
                            
                            id dateVar = [dateVariables objectAtIndex:j];
                                
                            if ( ![dateVar isKindOfClass:[NSString class]] )
                                [NSException raise:kExceptionWebAbstractConfigValidate
                                            format:@"'%@' in '%@' must be an NSString", dateVar, pathDesc3
                                 ];

                            if ( ![validDateComponents containsObject:dateVar] )
                                [NSException raise:kExceptionWebAbstractConfigValidate
                                            format:@"'%@' in '%@' is not a valid date component", dateVar, pathDesc3
                                 ];
                        }
                    }

                } else {
                            
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"value '%@' for key 'type' in '%@' is not a valid type", type, pathDesc2
                     ];
                }
                    
            } else if ( [variableVal isKindOfClass:[NSString class]] ) {
                        
                // this is valid
                        
            } else {
                        
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"'%@' must be either an NSString or an NSDictionary", pathDesc2
                 ];
            }
        }
        
        [mutableUrl setObject:variables forKey:@"variables"];
    }

    id postVariables = [url objectForKey:@"postVariables"];
    if ( postVariables ) {
                
        if ( ![postVariables isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'postVariables' in '%@' must be an NSDictionary", pathDescUrl
             ];
        
        NSString *pathDesc2 = [NSString stringWithFormat:@"%@.postVariables", pathDescUrl];
        
        NSMutableDictionary *mutablePostVariables = [[NSMutableDictionary alloc] init];

        for ( id rawPostVariableKey in [postVariables allKeys] ) {
            
            if ( ![rawPostVariableKey isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"postVariable key '%@' in '%@' must be an NSString", rawPostVariableKey, pathDesc2
                 ];
            
            id postVariableVal = [postVariables objectForKey:rawPostVariableKey];
            NSString *postVariableKey = [self removeCurlyBrackets:rawPostVariableKey];
            if ( ![postVariableVal isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"if specified, value for key '%@' in '%@' must be an NSString", postVariableKey, pathDesc2
                 ];
            
            HttpPostValue *postValue = [HttpPostValue new];
            NSString *unquotedVal = [self removeSingleQuotes:postVariableVal];
            if ( ![unquotedVal isEqualToString:postVariableVal] ) {
                
                // literal POST value
                postValue.type = HttpPostValueLiteral;
                postValue.value = unquotedVal;
                
            } else {
                
                // variable POST value
                postValue.type = HttpPostValueVariable;
                postValue.value = postVariableVal;
            }

            [mutablePostVariables setObject:postValue forKey:postVariableKey];
        }
                   
        mutableUrl[@"postVariables"] = [NSDictionary dictionaryWithDictionary:mutablePostVariables];
    }
    
    id userAgent = [url objectForKey:@"userAgent"];
    if ( userAgent ) {
        
        if ( ![userAgent isKindOfClass:[NSString class]] ) {
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'userAgent' in '%@' must be an NSString", pathDescUrl
             ];
        }
        
        mutableUrl[@"userAgent"] = userAgent;
    }

    [mutableSourceStruct setObject:[NSDictionary dictionaryWithDictionary:mutableUrl] forKey:@"url"];

    return [NSDictionary dictionaryWithDictionary:mutableSourceStruct];
}

+(NSDictionary *)validateAndFormatOutputStruct:(NSDictionary *)aOutputStruct
                                  withDefaults:(NSDictionary *)aDefaults
                                   forPathDesc:(NSString *)aPathDesc
{
    static NSSet *validKeys, *requiredKeys;
    if ( !validKeys ) {
        
        NSArray *required = @[];
        NSArray *valid    = @[@"serializationType", @"parse", @"parseCycles", @"parseCyclesUntilSuccess", @"parseCyclesMergeKeys", @"eachGroup", @"groupByPattern", @"caseInsensitive", @"matchWithinRange"];
        
        requiredKeys = [NSSet setWithArray:required];
        validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
    }
    
    [self validateDict:aOutputStruct forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:aPathDesc];
    
    NSMutableDictionary *mutableOutputStruct = [[NSMutableDictionary alloc] init];
   
    NSString *serializationType;
    int serializationTypeSpecified = 0;
    if ( aOutputStruct[@"serializationType"] ) {
        
        if ( [aOutputStruct[@"serializationType"] isEqualToString:@"JSON"] ) {
            
            serializationType = @"JSON";
            serializationTypeSpecified = 1;
            
        } else if ( [aOutputStruct[@"serializationType"] isEqualToString:@"HTML"] ) {
            
            serializationType = @"HTML";
            
        } else {
            
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, serializationType at %@ must be 'JSON' or 'HTML'", aPathDesc
             ];
        }
        
    } else {
        
        serializationType = @"HTML";
    }
    
    mutableOutputStruct[@"serializationType"] = serializationType;
   
    NSString *arrayTag;
    BOOL mustReturnDict = NO;
    
    int parseCyclesSpecified = 0;
    if ( [aOutputStruct objectForKey:@"parseCycles"] ) {
        parseCyclesSpecified = 1;
        arrayTag = @"parseCycles";
    }

    int parseCyclesUntilSuccessSpecified = 0;
    if ( [aOutputStruct objectForKey:@"parseCyclesUntilSuccess"] ) {
        parseCyclesUntilSuccessSpecified = 1;
        arrayTag = @"parseCyclesUntilSuccess";
    }
    
    int parseCyclesMergeKeysSpecified = 0;
    if ( [aOutputStruct objectForKey:@"parseCyclesMergeKeys"] ) {
        parseCyclesMergeKeysSpecified = 1;
        arrayTag = @"parseCyclesMergeKeys";
        mustReturnDict = YES;
    }

    if ( arrayTag ) {
        
        id arrayVal = [aOutputStruct objectForKey:arrayTag];

        if ( ![arrayVal isKindOfClass:[NSArray class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"value for key '%@' in '%@' must be an NSArray", arrayTag, aPathDesc
             ];
        
        NSMutableArray *mutableArrayVal = [[NSMutableArray alloc] init];
        
        for ( int i = 0; i < [arrayVal count]; i++ ) {
            id parseEntry = [arrayVal objectAtIndex:i];
            [mutableArrayVal addObject:[self validateAndFormatParseStruct:parseEntry
                                                             withDefaults:aDefaults
                                                           mustReturnDict:mustReturnDict
                                                              forPathDesc:[NSString stringWithFormat:@"%@.%@[%d]", aPathDesc, arrayTag, i]
                                        ]
             ];
        }
        
        [mutableOutputStruct setObject:[NSArray arrayWithArray:mutableArrayVal]
                                forKey:arrayTag
         ];
    }
    
    int parseSpecified = 0;
    id parse = [aOutputStruct objectForKey:@"parse"];
    if ( parse ) {
        parseSpecified = 1;
        [mutableOutputStruct setObject:[self validateAndFormatParseStruct:parse
                                                             withDefaults:aDefaults
                                                           mustReturnDict:NO
                                                              forPathDesc:[NSString stringWithFormat:@"%@.parse", aPathDesc]]
                                forKey:@"parse"
         ];
    }

    int eachGroupSpecified = 0;
    id eachGroup = [aOutputStruct objectForKey:@"eachGroup"];
    if ( eachGroup ) {

        eachGroupSpecified = 1;
        id groupByPattern = [aOutputStruct objectForKey:@"groupByPattern"];
        if ( groupByPattern ) {

            if ( ![groupByPattern isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key 'groupByPattern' in '%@' must be an NSString", aPathDesc
                 ];
            
            int options = NSRegularExpressionDotMatchesLineSeparators;
            id caseInsensitive = [aOutputStruct objectForKey:@"caseInsensitive"];
            if ( caseInsensitive ) {
                
                if ( ![caseInsensitive isKindOfClass:[NSNumber class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"if specified, value for key 'caseInsensitive' in '%@' must be a Boolean NSNumber", caseInsensitive
                     ];
                
                options |= [caseInsensitive boolValue];
                
            } else {
                
                id patternsCaseInsensitive = [aDefaults objectForKey:@"patternsCaseInsensitive"];
                if ( patternsCaseInsensitive ) {
                    options |= [patternsCaseInsensitive boolValue];
                }
            }

            NSError *error;
            NSRegularExpression *groupByRegEx = [NSRegularExpression regularExpressionWithPattern:groupByPattern
                                                                                          options:options
                                                                                            error:&error
                                                 ];
            
            if ( error )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"groupByPattern '%@' in '%@' could not be compiled. Error: %@", groupByPattern, aPathDesc, [error localizedDescription]
                 ];
                
            if ( groupByRegEx.numberOfCaptureGroups < 1) {
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"groupByPattern '%@' must capture at least one substring in '%@'", groupByPattern, aPathDesc
                 ];
            }
            
            [mutableOutputStruct setObject:groupByRegEx forKey:@"_groupByRegEx"];
            
        } else {
            
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"cannot specify an 'eachGroup' entry without an 'groupByPattern' entry in '%@'", aPathDesc
             ];
        }
        
        if ( ![eachGroup isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'eachGroup' in '%@' must be an NSDictionary", aPathDesc
             ];

        [mutableOutputStruct setObject:[self validateAndFormatOutputStruct:eachGroup
                                                              withDefaults:aDefaults
                                                               forPathDesc:[NSString stringWithFormat:@"%@.eachGroup", aPathDesc]]
                                forKey:@"eachGroup"
         ];
        
    } else if ( [aOutputStruct objectForKey:@"caseInsensitive"] ) {
        
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"cannot specify 'caseInsensitive' at this level without a 'groupByPattern' at '%@'", aPathDesc
         ];
    }
    
    if ( !eachGroupSpecified && [aOutputStruct objectForKey:@"groupByPattern"] )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"cannot specify 'groupByPattern' without an 'eachGroup' entry in '%@'", aPathDesc
         ];
    
    int instructionsSpecified =  parseCyclesSpecified
                               + parseCyclesUntilSuccessSpecified
                               + parseCyclesMergeKeysSpecified
                               + parseSpecified
                               + eachGroupSpecified
                               + serializationTypeSpecified;

    if ( instructionsSpecified == 0 )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"no valid parse instruction entry found in '%@'", aPathDesc
         ];
    
    if ( instructionsSpecified > 1 )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"only one parse instruction can be specified in '%@'", aPathDesc
         ];
    
    id matchWithinRange = [aOutputStruct objectForKey:@"matchWithinRange"];
    if ( matchWithinRange ) {
        
        NSMutableDictionary *mutableMatchWithinRange = [[NSMutableDictionary alloc] init];
        
        if ( ![matchWithinRange isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'matchWithinRange' in '%@' must be an NSDictionary", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.matchWithinRange", aPathDesc];

        static NSSet *validKeys, *requiredKeys;
        if ( !validKeys ) {
            
            NSArray *required = @[];
            NSArray *valid    = @[@"startAtPattern", @"startAtPatternInc", @"endAtPattern", @"endAtPatternInc", @"caseInsensitive", @"startIndexMatchNo", @"endIndexMatchNo"];
            
            requiredKeys = [NSSet setWithArray:required];
            validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
        }
        
        [self validateDict:matchWithinRange forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:pathDesc];
        
        int options = NSRegularExpressionDotMatchesLineSeparators;
        id caseInsensitive = [aOutputStruct objectForKey:@"caseInsensitive"];
        if ( caseInsensitive ) {
            
            if ( ![caseInsensitive isKindOfClass:[NSNumber class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"if specified, value for key 'caseInsensitive' in '%@' must be a Boolean NSNumber", caseInsensitive
                 ];
            
            options |= [caseInsensitive boolValue];
            
        } else {
            
            id patternsCaseInsensitive = [aDefaults objectForKey:@"patternsCaseInsensitive"];
            if ( patternsCaseInsensitive ) {
                options |= [patternsCaseInsensitive boolValue];
            }
        }
        
        id startAtPattern    = [matchWithinRange objectForKey:@"startAtPattern"];
        id startAtPatternInc = [matchWithinRange objectForKey:@"startAtPatternInc"];
        if ( startAtPattern ) {
            
            if ( ![startAtPattern isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for 'startAtPattern' in '%@' is not an NSString", pathDesc
                 ];
            
            NSError *error;
            NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:startAtPattern
                                                                                   options:options
                                                                                     error:&error
                                          ];
            
            if ( error )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"regular expression '%@' for key 'startAtPattern' in '%@' could not be compiled. Error: %@", startAtPattern, pathDesc, [error localizedDescription]
                 ];
            
            [mutableMatchWithinRange setObject:regEx forKey:@"_startAtRegEx"];
            
            if ( startAtPatternInc ) {
                
                if ( ![startAtPatternInc isKindOfClass:[NSNumber class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"if specified, 'startAtPatternInc' in '%@' must be an (boolean) NSNumber value", pathDesc
                     ];
                
                if ( [startAtPatternInc boolValue] == YES )
                    [mutableMatchWithinRange setObject:@YES forKey:@"startAtPatternInc"];
            }

        } else {
            
            if ( startAtPatternInc )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"cannot specify 'startAtPatternInc' in '%@' without 'startAtPattern'", pathDesc
                 ];
        }
        
        id endAtPattern    = [matchWithinRange objectForKey:@"endAtPattern"];
        id endAtPatternInc = [matchWithinRange objectForKey:@"endAtPatternInc"];
        if ( endAtPattern ) {
            
            if ( ![endAtPattern isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key 'endAtPattern' in '%@' is not an NSString", pathDesc
                 ];
            
            NSError *error;
            NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:endAtPattern
                                                                                   options:options
                                                                                     error:&error
                                          ];
            
            if ( error )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"regular expression '%@' for key 'endAtPattern' in '%@' could not be compiled. Error: %@", endAtPattern, pathDesc, [error localizedDescription]
                 ];
            
            [mutableMatchWithinRange setObject:regEx forKey:@"_endAtRegEx"];

            if ( endAtPatternInc ) {
                
                if ( ![endAtPatternInc isKindOfClass:[NSNumber class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"if specified, 'endAtPatternInc' in '%@' must be an (boolean) NSNumber value", pathDesc
                     ];
                
                if ( [endAtPatternInc boolValue] == YES )
                    [mutableMatchWithinRange setObject:@YES forKey:@"endAtPatternInc"];
            }
            
        } else {
            
            if ( endAtPatternInc )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"cannot specify 'endAtPatternInc' in '%@' without 'endAtPattern'", pathDesc
                 ];
        }
        
        id endIndexMatchNo = [matchWithinRange objectForKey:@"endIndexMatchNo"];
        if ( endIndexMatchNo ) {
            
            if ( ![endIndexMatchNo isKindOfClass:[NSNumber class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"if specified, value for key 'endIndexMatchNo' in '%@' must be an integer NSNumber", pathDesc
                 ];
            
            [mutableMatchWithinRange setObject:endIndexMatchNo forKey:@"endIndexMatchNo"];
        }
        
        [mutableOutputStruct setObject:mutableMatchWithinRange forKey:@"matchWithinRange"];
    }
    
    return [NSDictionary dictionaryWithDictionary:mutableOutputStruct];
}

+(NSDictionary *)validateAndFormatParseStruct:(NSDictionary *)aParseStruct
                                 withDefaults:(NSDictionary *)aDefaults
                               mustReturnDict:(BOOL)aMustReturnDict
                                  forPathDesc:(NSString *)aPathDesc
{
    static NSSet *validKeys, *requiredKeys;
    if ( !validKeys ) {
        
        NSArray *required = @[];
        NSArray *valid    = @[@"xPath", @"pattern", @"captures", @"xCaptures", @"caseInsensitive", @"matchIteration", @"matchesAsArray", @"appendingMatches", @"defaultValues", @"matchValues"];

        requiredKeys = [NSSet setWithArray:required];
        validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
    }
    
    [self validateDict:aParseStruct forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:aPathDesc];
    
    NSMutableDictionary *mutableParseStruct = [NSMutableDictionary dictionaryWithDictionary:aParseStruct];
    
    id xPath = [aParseStruct objectForKey:@"xPath"];
    if ( xPath ) {
        if ( ![xPath isKindOfClass:[NSString class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"value for key 'xPath' in '%@' must be an NSString", aPathDesc
             ];
    }
    
    int highestCaptureSpecified = 0;
    
    id captures = [aParseStruct objectForKey:@"captures"];
    if ( captures ) {
        
        if ( ![captures isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'captures' in '%@' must be an NSDictionary", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.captures", aPathDesc];
        
        NSMutableDictionary *mutableCaptures = [[NSMutableDictionary alloc] init];
        
        for ( id rawCaptureKey in [captures allKeys] ) {
            
            if ( ![rawCaptureKey isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"capture key '%@' in '%@' must be an NSString", rawCaptureKey, pathDesc
                 ];
            
            // bypass "commented out" configurations
            if ( [[rawCaptureKey substringToIndex:2] isEqualToString:@"//"] ) continue;
            
            id captureVal = [captures objectForKey:rawCaptureKey];
            NSString *captureKey = [self removeCurlyBrackets:rawCaptureKey];
            [mutableCaptures setObject:captureVal forKey:captureKey];
            
            if ( ![captureVal isKindOfClass:[NSNumber class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"if specified, value for key '%@' in '%@' must be an NSNumber", captureKey, pathDesc
                 ];
            
            int captureValInt = [captureVal intValue];
            
            if ( captureValInt < 1 )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for capture key '%@' in '%@' must be a positive integer NSNumber", captureKey, pathDesc
                 ];
            
            if ( captureValInt > highestCaptureSpecified )
                highestCaptureSpecified = captureValInt;
        }
        
        [mutableParseStruct setObject:[NSDictionary dictionaryWithDictionary:mutableCaptures] forKey:@"captures"];
    }

    id xCaptures = [aParseStruct objectForKey:@"xCaptures"];
    if ( xCaptures ) {
        
        if ( !xPath )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"cannot specify 'xCaptures' in '%@' without also specifying 'xPath'", aPathDesc
             ];

        if ( ![xCaptures isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'xCaptures' in '%@' must be an NSDictionary", aPathDesc
             ];
        
        if ( captures )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"cannot specify both 'captures' and 'xCaptures' in '%@'", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.xCaptures", aPathDesc];
        
        NSMutableDictionary *mutableXCaptures = [[NSMutableDictionary alloc] init];
        
        for ( id rawXCaptureKey in [xCaptures allKeys] ) {
            
            if ( ![rawXCaptureKey isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"capture key '%@' in '%@' must be an NSString", rawXCaptureKey, pathDesc
                 ];
            
            // bypass "commented out" configurations
            if ( [[rawXCaptureKey substringToIndex:2] isEqualToString:@"//"] ) continue;
            
            id xCaptureVal = [xCaptures objectForKey:rawXCaptureKey];
            NSString *xCaptureKey = [self removeCurlyBrackets:rawXCaptureKey];
            
            if ( ![xCaptureVal isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"if specified, value for key '%@' in '%@' must be an NSString", xCaptureKey, pathDesc
                 ];
            
            NSString *pathDesc2 = [NSString stringWithFormat:@"%@[%@]", pathDesc, xCaptureKey];

            static NSRegularExpression *xCaptureRegEx = nil;
            
            if ( !xCaptureRegEx ) {
                xCaptureRegEx = [NSRegularExpression regularExpressionWithPattern:@"^([\\w\\.\\{\\}\\[\\]\\@]+)(?:\\s*[#/](.*)[#/])?"
                                                                          options:0
                                                                            error:NULL
                                 ];
            }
            
            NSTextCheckingResult *result = [xCaptureRegEx firstMatchInString:xCaptureVal
                                                                     options:0
                                                                       range:NSMakeRange(0, [xCaptureVal length])
                                            ];
            
            NSMutableArray *mutableOps = [NSMutableArray new];
            NSRegularExpression *filterRegEx;
            if ( result ) {
                
                NSString *rawFuncsStr = [xCaptureVal substringWithRange:[result rangeAtIndex:1]];
                NSArray *funcStrs = [rawFuncsStr componentsSeparatedByString:@"."];
                
                for ( NSString *funcStr in funcStrs ) {
                    
                    NSString *func;
                    NSMutableArray *params = [NSMutableArray new];
                    
                    for ( NSRegularExpression *hppleRegEx in validHppleRegExs.allKeys ) {
                        
                        NSTextCheckingResult *match = [hppleRegEx firstMatchInString:funcStr
                                                                             options:0
                                                                               range:NSMakeRange(0, funcStr.length)
                                                       ];
                        
                        if ( match ) {

                            func = [validHppleRegExs objectForKey:hppleRegEx];

                            for ( int i = 1; i < match.numberOfRanges; i++ ) {
                                id param;
                                if ( [match rangeAtIndex:i].location == NSNotFound ) {
                                    param = [NSNull null];
                                } else {
                                    param = [funcStr substringWithRange:[match rangeAtIndex:i]];
                                }
                                [params addObject:param];
                            }
                            
                            break;
                        }
                    }
                    
                    if ( !func ) {
                        [NSException raise:kExceptionWebAbstractConfigValidate
                                    format:@"xCapture expression '%@' in '%@' is not valid", funcStr, pathDesc2
                         ];
                    }

                    HppleOp *op = [HppleOp new];
                    op.func = func;
                    op.params = [NSArray arrayWithArray:params];
                    
                    [mutableOps addObject:op];
                }
            
                NSRange filterRange = [result rangeAtIndex:2];
                if ( filterRange.location != NSNotFound && filterRange.length > 0 ) {
                    
                    NSString *filterPattern = [xCaptureVal substringWithRange:filterRange];
                    
                    NSError *error;
                    filterRegEx = [NSRegularExpression regularExpressionWithPattern:filterPattern
                                                                            options:NSRegularExpressionDotMatchesLineSeparators
                                                                              error:&error
                                   ];
                    
                    if ( error ) {
                        [NSException raise:kExceptionWebAbstractConfigValidate
                                    format:@"Filter regular expression '%@' specified in '%@' could not be compiled", filterPattern, pathDesc2
                         ];
                    }
                    
                    if ( filterRegEx.numberOfCaptureGroups != 1 )
                        [NSException raise:kExceptionWebAbstractConfigValidate
                                    format:@"Filter regular expression '%@' specified in '%@' must specify exactly one capture group", filterPattern, pathDesc2
                         ];
                }
                
                XCapture *xCapture = [XCapture new];
                xCapture.hppleOps = [NSArray arrayWithArray:mutableOps];
                xCapture.filter = filterRegEx ? filterRegEx : defaultPatternRegEx;
         
                [mutableXCaptures setObject:xCapture forKey:xCaptureKey];
             
            } else {
                
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"xCapture expression is not of a valid format in '%@'", pathDesc2
                 ];
            }
        }
        
        [mutableParseStruct setObject:[NSDictionary dictionaryWithDictionary:mutableXCaptures] forKey:@"xCaptures"];
    }

    NSDictionary *matchValues   = [aParseStruct objectForKey:@"matchValues"];
    NSDictionary *defaultValues = [aParseStruct objectForKey:@"defaultValues"];
    
    if ( aMustReturnDict && !captures && !xCaptures && !defaultValues && !matchValues )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"parse entry at '%@' must return an NSDictionary", aPathDesc
         ];

    id pattern = [aParseStruct objectForKey:@"pattern"];
    if ( pattern ) {

        if ( ![pattern isKindOfClass:[NSString class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"value for key 'pattern' in '%@' must be an NSString", aPathDesc
             ];
        
        if ( xCaptures )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"cannot specify 'xCaptures' in '%@' if 'pattern' is also specified", aPathDesc
             ];
    
        NSString *pathDesc = [NSString stringWithFormat:@"%@.pattern", aPathDesc];
    
        int options = NSRegularExpressionDotMatchesLineSeparators;
        id caseInsensitive = [aParseStruct objectForKey:@"caseInsensitive"];
        if ( caseInsensitive ) {
        
            if ( ![caseInsensitive isKindOfClass:[NSNumber class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"if specified, value for key 'caseInsensitive' in '%@' must be a Boolean NSNumber", caseInsensitive
                 ];
        
            options |= [caseInsensitive boolValue];
        
        } else {
        
            id patternsCaseInsensitive = [aDefaults objectForKey:@"patternsCaseInsensitive"];
            if ( patternsCaseInsensitive ) {
                options |= [patternsCaseInsensitive boolValue];
            }
        }
    
        NSError *error;
        NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:options
                                                                                 error:&error
                                      ];

        if ( error )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"regular expression pattern '%@' in '%@' could not be compiled. Error: %@", pattern, pathDesc, [error localizedDescription]
             ];
        
        BOOL shouldReturnDict = [aParseStruct objectForKey:@"matchValues"] || [aParseStruct objectForKey:@"defaultValues"] || [aParseStruct objectForKey:@"captures"];
        
        if ( !shouldReturnDict && regEx.numberOfCaptureGroups == 0 )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"'pattern' ('%@') must capture at least one substring at '%@' if none of 'matchValues', 'defaultValues', or 'captures' is specified", pattern, pathDesc
             ];
        
        if ( highestCaptureSpecified > regEx.numberOfCaptureGroups )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"pattern '%@' captures only %d substring(s), so 'captures' dictionary cannot specify an out-of-range capture group (%d) in '%@'", pattern, (int)regEx.numberOfCaptureGroups,highestCaptureSpecified, pathDesc
             ];
    
        [mutableParseStruct setObject:regEx forKey:@"_regEx"];

    } else {
        
        if ( captures )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"cannot specify key 'captures' if value for key 'pattern' is not specified in '%@'", aPathDesc
             ];
     
        [mutableParseStruct setObject:defaultPatternRegEx forKey:@"_regEx"];
    }
    
    if ( !xPath && !pattern )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"Must specify at least one of 'xPath' and/or 'pattern' keys in '%@'", aPathDesc
         ];

    int matchIterationSpecified = 0;
    
    NSNumber *matchIteration;
    id rawMatchIteration = [aParseStruct objectForKey:@"matchIteration"];
    if ( rawMatchIteration ) {
        
        matchIterationSpecified = 1;
        
        if ( ![rawMatchIteration isKindOfClass:[NSNumber class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'matchIteration' in '%@' must be an NSNumber", aPathDesc
             ];

        if ( [rawMatchIteration integerValue] < 1 )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'matchIteration' '%@' in '%@' must an integer value of 1 or greater", rawMatchIteration, aPathDesc
             ];
        
        matchIteration = rawMatchIteration;

    } else {
     
        matchIteration = @1;
    }
    
    [mutableParseStruct setObject:matchIteration forKey:@"matchIteration"];

    int matchesAsArraySpecified = 0;
    
    id matchesAsArray = [aParseStruct objectForKey:@"matchesAsArray"];
    if ( matchesAsArray ) {
        
        matchesAsArraySpecified = 1;
        
        if ( ![matchesAsArray isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'matchesAsArray' in '%@' must be an NSDictionary", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.matchesAsArray", aPathDesc];

        static NSSet *validKeys, *requiredKeys;
        if ( !validKeys ) {
            
            NSArray *required = @[];
            NSArray *valid    = @[@"startIndex", @"endIndex", @"all"];
            
            requiredKeys = [NSSet setWithArray:required];
            validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
        }
        
        [self validateDict:matchesAsArray forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:pathDesc];

        id startIndex = [matchesAsArray objectForKey:@"startIndex"];
        if ( startIndex ) {
            
            if ( ![startIndex isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key 'startIndex' in '%@' must be an NSString", pathDesc
                 ];
        }

        id endIndex = [matchesAsArray objectForKey:@"endIndex"];
        if ( endIndex ) {
            
            if ( ![endIndex isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key 'endIndex' in '%@' must be an NSString", pathDesc
                 ];
        }
        
        id all = [matchesAsArray objectForKey:@"all"];
        if ( all ) {
            
            if ( ![all isKindOfClass:[NSNumber class]] || ![all boolValue] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"if specified, value for key 'all' in '%@' must be a true NSNumber value", pathDesc
                 ];
            
            if ( startIndex )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"'all' entry cannot be specified if key 'startIndex' is specified in '%@'", pathDesc
                 ];
                
            if ( endIndex )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"'all' entry cannot be specified if key 'endIndex' is specified in '%@'", pathDesc
                 ];
            
        } else if ( !startIndex && !endIndex ) {

            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"'all' entry must be specified if neither 'startIndex' nor 'endIndex' are specified in '%@'", pathDesc
             ];
        }
    }

    id appendingMatches = [aParseStruct objectForKey:@"appendingMatches"];

    int appendingMatchesSpecified = 0;
    if ( appendingMatches ) {
        
        NSMutableDictionary *mutableAppendingMatches = [NSMutableDictionary dictionaryWithDictionary:appendingMatches];

        appendingMatchesSpecified = 1;
        
        if ( ![appendingMatches isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"if specified, value for key 'appendingMatches' in '%@' must be an NSDictionary", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.appendingMatches", aPathDesc];
        
        static NSSet *validKeys, *requiredKeys;
        if ( !validKeys ) {
            
            NSArray *required = @[@"append"];
            NSArray *valid    = @[@"startIndex", @"endIndex", @"joinWith"];
            
            requiredKeys = [NSSet setWithArray:required];
            validKeys = [requiredKeys setByAddingObjectsFromArray:valid];
        }
        
        [self validateDict:appendingMatches forRequiredKeys:requiredKeys forValidKeys:validKeys forPathDesc:pathDesc];

        id startIndex = [appendingMatches objectForKey:@"startIndex"];
        if ( startIndex ) {
            
            if ( ![startIndex isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key 'startIndex' in '%@' must be an NSString", pathDesc
                 ];
        }
        
        id endIndex = [appendingMatches objectForKey:@"endIndex"];
        if ( endIndex ) {
            
            if ( ![endIndex isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key 'endIndex' in '%@' must be an NSString", pathDesc
                 ];
        }
        
        id joinWith = [appendingMatches objectForKey:@"joinWith"];
        if ( joinWith ) {
            if ( ![joinWith isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key 'joinWith' in '%@' must be an NSString", pathDesc
                 ];
        }
        
        id append = [appendingMatches objectForKey:@"append"];
        if ( ![append isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"value for key 'append' in '%@' must be an NSDictionary", pathDesc
             ];
        
        if ( [append count] == 0 )
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"dictionary for key 'append' in '%@' must have at least one entry", pathDesc
             ];
        
        NSMutableDictionary *mutableAppend = [[NSMutableDictionary alloc] init];
        
        for ( id rawAppendKey in [append allKeys] ) {
                
            if ( ![rawAppendKey isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key '%@' in 'append' dictionary in '%@' is not an NSString", rawAppendKey, pathDesc
                 ];
                
            id val = [append objectForKey:rawAppendKey];
            NSString *appendKey = [self removeCurlyBrackets:rawAppendKey];
            [mutableAppend setObject:val forKey:appendKey];

            if ( ![val isKindOfClass:[NSNumber class]] ) {
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"value for key '%@' in 'append' dictionary in '%@' is not a true NSNumber", appendKey, pathDesc
                 ];
            }
        }
        
        [mutableAppendingMatches setObject:mutableAppend forKey:@"append"];
        [mutableParseStruct setObject:mutableAppendingMatches forKey:@"appendingMatches"];
    }

    int instructionsSpecified = matchIterationSpecified + matchesAsArraySpecified + appendingMatchesSpecified;
    if ( instructionsSpecified > 1 )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"only one parse instruction can be specified in '%@'", aPathDesc
         ];

    for ( NSString *type in @[ @"defaultValues", @"matchValues" ] ) {
        
        id entry;
        if ( ( entry = [aParseStruct objectForKey:type] ) ) {
        
            if ( ![entry isKindOfClass:[NSDictionary class]] )
                [NSException raise:kExceptionWebAbstractConfigValidate
                            format:@"if specified, value for key '%@' in '%@' must be an NSDictionary", type, aPathDesc
                 ];
            
            NSString *pathDesc = [NSString stringWithFormat:@"%@.%@", aPathDesc, type];

            NSMutableDictionary *mutableEntry = [[NSMutableDictionary alloc] init];
            
            for ( id rawKey in [entry allKeys] ) {
            
                if ( ![rawKey isKindOfClass:[NSString class]] )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"key '%@' in '%@' must be an NSString", rawKey, pathDesc
                     ];
            
                id val = [entry objectForKey:rawKey];
                NSString *key = [self removeCurlyBrackets:rawKey];
                [mutableEntry setObject:val forKey:key];
                
                if ( !( [val isKindOfClass:[NSString class]] || [val isKindOfClass:[NSNumber class]] ) )
                    [NSException raise:kExceptionWebAbstractConfigValidate
                                format:@"value for key '%@' in '%@' must be an NSString or NSNumber", key, pathDesc
                     ];
            }
            
            [mutableParseStruct setObject:[NSDictionary dictionaryWithDictionary:mutableEntry] forKey:type];
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:mutableParseStruct];
}

+(void)validateDict:(NSDictionary *)aDict
    forRequiredKeys:(NSSet *)aRequiredKeys
       forValidKeys:(NSSet *)aValidKeys
        forPathDesc:(NSString *)aPathDesc
{
    NSMutableSet *keysSeen = [NSMutableSet setWithSet:aRequiredKeys];
    for ( id key in aDict.allKeys ) {
    
        if ( ![key isKindOfClass:[NSString class]] ) {
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"key '%@' in '%@' must be an NSString", key, aPathDesc
             ];
        }
    
        // bypass "commented out" configurations
        if ( [[key substringToIndex:2] isEqualToString:@"//"] ) continue;
        
        if ( ![aValidKeys containsObject:key] ) {
            [NSException raise:kExceptionWebAbstractConfigValidate
                        format:@"key '%@' in '%@' is not a valid key", key, aPathDesc
             ];
        }
    
        [keysSeen removeObject:key];
    }

    NSString *unspecifiedKey = keysSeen.allObjects.lastObject;
    if ( unspecifiedKey )
        [NSException raise:kExceptionWebAbstractConfigValidate
                    format:@"key '%@' is required to be specified in '%@'", unspecifiedKey, aPathDesc
         ];
}

@end

