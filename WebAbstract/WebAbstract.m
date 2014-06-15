//
//  WebAbstract.m
//  Gymclass
//
//  Created by Eric Colton on 12/5/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import "WebAbstract.h"
#import "WebAbstractConfig.h"
#import "TFHpple.h"
#import "HttpPostValue.h"

@interface WebAbstract()

-(NSDictionary *)fetchOperation:(NSString *)aOperation
                   forSourceTag:(NSString *)aSourceTag;

-(NSString *)buildVariableStr:(id)aVarRaw withInputVariables:(NSDictionary *)aInputVars withPathDesc:(NSString *)aPathDesc;

-(NSDictionary *)fetchOperation:(NSString *)aOperation
                   forOutputTag:(NSString *)aOutputTag;

-(NSData *)extractSubData:(NSData *)aData
      forRangeMatchConfig:(NSDictionary *)aRangeMatchConfig;

-(NSDictionary *)parseData:(NSData *)aDataString
           forGroupByRegEx:(NSRegularExpression *)aGroupByRegEx
            forParseConfig:(NSDictionary *)aParseConfig;

-(id)parseData:(NSData *)aData forOutputConfig:(NSDictionary *)aOutputConfig;

-(id)parseDataForSingleCycle:(NSData *)aDataString
             forOutputConfig:(NSDictionary *)aParseConfig;

-(id)buildResultForMatch:(NSTextCheckingResult *)aMatch
          withDataString:(NSString *)aDataString
      withCapturesConfig:(NSDictionary *)aCapturesConfig
           startWithDict:(NSDictionary *)aStartWithDict;

@property (nonatomic, readonly) NSArray *configs;
@property (nonatomic, readonly) NSDictionary *defaults;
@property (nonatomic, readonly) NSString *urlHardPrefix;

@end

@implementation WebAbstract

@synthesize urlHardPrefix = _urlHardPrefix, configs = _configs;

////
#pragma mark init methods (public)
////
-(id)initWithConfig:(WebAbstractConfig *)aConfig
{
    return [self initWithConfigs:@[aConfig]];
}

-(id)initWithConfigs:(NSArray *)aConfigs
{
    if ( !aConfigs )
        [NSException raise:kExceptionWebAbstractSetup
                    format:@"method 'initWithConfigs:' must specify an NSArray"
         ];
    
    if ( aConfigs.count < 1 )
        [NSException raise:kExceptionWebAbstractSetup
                    format:@"method 'initWithConfig:' must specify an NSArray that contains at least one WebAbstractConfig object"
         ];
    
    self = [super init];
    if ( self ) {
        _configs = aConfigs;
    }
    
    return self;
}

////
#pragma mark instance methods (public)
////
-(BOOL)isOperationAvailable:(NSString *)aOperation
               forOutputTag:(NSString *)aOutputTag
{
    return !![self fetchOperation:aOperation forOutputTag:aOutputTag];
}

-(BOOL)isOperationAvailable:(NSString *)aOperation
               forSourceTag:(NSString *)aSourceTag
{
    return !![self fetchOperation:aOperation forOutputTag:aSourceTag];
}

-(NSMutableURLRequest *)buildUrlRequestForOperation:(NSString *)aOperation
                                       forSourceTag:(NSString *)aSourceTag
                                      withVariables:(NSDictionary *)aVariables
{
    NSString *pathDesc = [NSString stringWithFormat:@"sourceTag '%@' for operation '%@'", aSourceTag, aOperation];
    
    NSDictionary *sourceConfig = [self fetchOperation:aOperation forSourceTag:aSourceTag];
    if ( !sourceConfig )
        [NSException raise:kExceptionWebAbstractRuntime
                    format:@"No configuration found for %@", pathDesc
         ];

    NSDictionary *urlConfig = [sourceConfig objectForKey:@"url"];
    NSString *urlFormatStr = [urlConfig objectForKey:@"format"];
    
    NSString *protocol = [urlConfig objectForKey:@"protocol"];
    if ( !protocol ) protocol = @"http";

    NSArray *urlInterpolations = [urlConfig objectForKey:@"variables"];
    
    NSMutableArray *urlInterpolationValues = [[NSMutableArray alloc] initWithCapacity:10];
    
    for ( int i = 0; i < urlInterpolations.count; i++ ) {
        
        id interpolationRaw = [urlInterpolations objectAtIndex:i];
        NSString *entryPathDesc = [NSString stringWithFormat:@"url variable %d in %@", i, pathDesc];
        
        [urlInterpolationValues addObject:[self buildVariableStr:interpolationRaw
                                              withInputVariables:aVariables
                                                    withPathDesc:entryPathDesc
                                           ]
         ];
    }

    while ( urlInterpolationValues.count < 10 ) {
        [urlInterpolationValues addObject:[NSString string]];
    }
    
    NSString *fullUrlFormatStr = self.urlHardPrefix
                                 ? [NSString stringWithFormat:@"%@://%@/%@", protocol, self.urlHardPrefix, urlFormatStr]
                                 : [NSString stringWithFormat:@"%@://%@", protocol, urlFormatStr];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:fullUrlFormatStr,[urlInterpolationValues objectAtIndex:0]
                                                                                 ,[urlInterpolationValues objectAtIndex:1]
                                                                                 ,[urlInterpolationValues objectAtIndex:2]
                                                                                 ,[urlInterpolationValues objectAtIndex:3]
                                                                                 ,[urlInterpolationValues objectAtIndex:4]
                                                                                 ,[urlInterpolationValues objectAtIndex:5]
                                                                                 ,[urlInterpolationValues objectAtIndex:6]
                                                                                 ,[urlInterpolationValues objectAtIndex:7]
                                                                                 ,[urlInterpolationValues objectAtIndex:8]
                                                                                 ,[urlInterpolationValues objectAtIndex:9]
                                       ]
                  ];

    NSString *urlMethod = [urlConfig objectForKey:@"httpMethod"];
    
    NSMutableURLRequest *urlRequest;
    if ( [urlMethod isEqualToString:@"POST"] ) {

        urlRequest = [NSMutableURLRequest requestWithURL:url];
        urlRequest.HTTPMethod = @"POST";
        
        NSDictionary *configuredPostVariables = [urlConfig objectForKey:@"postVariables"];
        NSMutableString *postString = [[NSMutableString alloc] init];

        for ( NSString *configKey in configuredPostVariables.allKeys ) {
            
            HttpPostValue *postValue = [configuredPostVariables objectForKey:configKey];
            
            NSString *val;
            if ( postValue.type == HttpPostValueLiteral ) {
                
                val = postValue.value;
                
            } else { // otherwise is type HttpPostValueVariable
                
                val = [aVariables objectForKey:postValue.value];
                
                if ( !val )
                    [NSException raise:kExceptionWebAbstractRuntime
                                format:@"variables dictionary contains no value for POST variable key '%@'", postValue.value
                     ];
            }
            
            if ( postString.length > 0 ) [postString appendString:@"&"];
            [postString appendFormat:@"%@=%@", configKey, val];
        }

        const char *postCString = [postString cStringUsingEncoding:NSUTF8StringEncoding];
        urlRequest.HTTPBody = [NSData dataWithBytes:postCString length:strlen(postCString)];
     
    } else {
        
        urlRequest = [NSMutableURLRequest requestWithURL:url];
    }

    [urlRequest addValue:urlConfig[@"userAgent"] forHTTPHeaderField:@"User-Agent"];
    
    return urlRequest;
}


-(id)parseData:(NSData *)aData
  forOperation:(NSString *)aOperation
  forOutputTag:(NSString *)aOutputTag
{
    NSDictionary *outputConfig = [self fetchOperation:aOperation forOutputTag:aOutputTag];
    if ( !outputConfig )
        [NSException raise:kExceptionWebAbstractRuntime
                    format:@"no configuration for outputTag '%@' for operation '%@'", aOutputTag, aOperation
         ];

    return [self parseData:aData forOutputConfig:outputConfig];
}

-(void)setUrlHardPrefix:(NSString *)aPrefix
{
    if ( self.urlHardPrefix ) {
        
        [NSException raise:kExceptionWebAbstractRuntime
                    format:@"cannot set hardUrlPrefix on a webAbstract object more than once"
         ];
        
    } else {
        
        _urlHardPrefix = aPrefix;
    }
}

////
#pragma mark instance methods (private)
////
-(NSDictionary *)fetchOperation:(NSString *)aOperation forSourceTag:(NSString *)aSourceTag
{
    for ( WebAbstractConfig *config in self.configs ) {
        
        NSDictionary *sourceConfig = [config fetchConfigForOperation:aOperation forSourceTag:aSourceTag];
        if ( sourceConfig ) return sourceConfig;
    }
    
    return nil;
}

-(NSDictionary *)fetchOperation:(NSString *)aOperation forOutputTag:(NSString *)aOutputTag
{
    for ( WebAbstractConfig *config in self.configs ) {
        NSDictionary *outputConfig =[config fetchConfigForOperation:aOperation forOutputTag:aOutputTag];
        if ( outputConfig ) return outputConfig;
    }
    
    return nil;
}

-(id)parseData:(NSData *)aData forOutputConfig:(NSDictionary *)aOutputConfig
{
    NSString *serializationType      = [aOutputConfig objectForKey:@"serializationType"];
    NSArray *parseCycles             = [aOutputConfig objectForKey:@"parseCycles"];
    NSArray *parseCyclesUntilSuccess = [aOutputConfig objectForKey:@"parseCyclesUntilSuccess"];
    NSArray *parseCyclesMergeKeys    = [aOutputConfig objectForKey:@"parseCyclesMergeKeys"];
    NSDictionary *parse              = [aOutputConfig objectForKey:@"parse"];
    NSDictionary *eachGroup          = [aOutputConfig objectForKey:@"eachGroup"];

    NSData *usableData;
    
    NSDictionary *rangeMatchConfig = [aOutputConfig objectForKey:@"matchWithinRange"];
    if ( rangeMatchConfig ) {
        
        usableData = [self extractSubData:aData forRangeMatchConfig:rangeMatchConfig];

    } else {
        
        usableData = aData;
    }
    
    if ( [serializationType isEqualToString:@"JSON"] ) {
        
        NSError *error = nil;
        id rv = [NSJSONSerialization JSONObjectWithData:usableData options:0 error:&error];
        
        if ( error ) {
            [NSException raise:kExceptionWebAbstractRuntime
                        format:@"Unable to parse expected-JSON response"
             ];
        } else {

            return rv;
        }
    }
    
    if ( parseCycles ) {

        NSMutableArray *cyclesResults = [[NSMutableArray alloc] init];
        for ( NSDictionary *parseCycleConfig in parseCycles ) {
            [cyclesResults addObject:[self parseDataForSingleCycle:usableData forOutputConfig:parseCycleConfig]];
        }
        return cyclesResults;
        
    } else if ( parseCyclesUntilSuccess ) {
        
        for ( NSDictionary *parseCycleConfig in parseCyclesUntilSuccess ) {
            id result = [self parseDataForSingleCycle:usableData forOutputConfig:parseCycleConfig];

            if ( result
                 && ( [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSDictionary class]] )
                 && [result count] > 0
               ) {
                return result;
            }
        }
        return nil;
        
    } else if ( parseCyclesMergeKeys ) {
        
        NSMutableDictionary *combinedDict = [[NSMutableDictionary alloc] init];
        for ( NSDictionary *parseCycleConfig in parseCyclesMergeKeys ) {
            NSDictionary *partialDict = [self parseDataForSingleCycle:usableData forOutputConfig:parseCycleConfig];
            [combinedDict addEntriesFromDictionary:partialDict];
        }
        return combinedDict;
        
    } else if ( parse ) {
        
        return [self parseDataForSingleCycle:usableData forOutputConfig:parse];

    } else if ( eachGroup ) {

        return [self parseData:usableData
                     forGroupByRegEx:[aOutputConfig objectForKey:@"_groupByRegEx"]
                      forParseConfig:eachGroup
                ];
    }

    return nil; // never reached
}

-(NSData *)extractSubData:(NSData *)aData
      forRangeMatchConfig:(NSDictionary *)aRangeMatchConfig
{
    NSString *dataString = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    
    NSRange returnRange = NSMakeRange(0, dataString.length);
    
    int startIndexMatchNo             = [[aRangeMatchConfig objectForKey:@"startIndexMatchNo"] intValue];
    int endIndexMatchNo               = [[aRangeMatchConfig objectForKey:@"endIndexMatchNo"] intValue];
    NSRegularExpression *startAtRegEx = [aRangeMatchConfig objectForKey:@"_startAtRegEx"];
    NSRegularExpression *endAtRegEx   = [aRangeMatchConfig objectForKey:@"_endAtRegEx"];
        
    if ( startAtRegEx ) {
        
        NSArray *startMatches = [startAtRegEx matchesInString:dataString
                                                      options:0
                                                        range:NSMakeRange(0, dataString.length)
                                 ];
            
        if ( startMatches.count <= startIndexMatchNo ) return aData;
            
        NSTextCheckingResult *startMatch = [startMatches objectAtIndex:startIndexMatchNo];

        NSRange startRange = [startMatch rangeAtIndex:0];

        returnRange.location = startRange.location;
        
        if ( [[aRangeMatchConfig objectForKey:@"startAtPatternInc"] boolValue] != YES )
            returnRange.location += startRange.length;

        returnRange.length = dataString.length - returnRange.location;
    }

    if ( endAtRegEx ) {
        
        NSArray *endMatches = [endAtRegEx matchesInString:dataString
                                                  options:0
                                                    range:NSMakeRange(0, dataString.length)
                               ];
            
        if ( endMatches.count ) {
            
            for ( NSTextCheckingResult *endMatch in endMatches ) {
                
                int endMatchLoc    = (int)[endMatch rangeAtIndex:0].location;
                int endMatchLength = (int)[endMatch rangeAtIndex:0].length;

                int endMatchCountdown = endIndexMatchNo;
                if ( endMatchLoc > returnRange.location ) {
                    
                    returnRange.length = endMatchLoc - returnRange.location;

                    if ( [[aRangeMatchConfig objectForKey:@"endAtPatternInc"] boolValue] == YES )
                        returnRange.length += endMatchLength;
                    
                    if ( !endMatchCountdown-- )
                        break;
                }
            }
        }
    }
    
    return [[dataString substringWithRange:returnRange] dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSDictionary *)parseData:(NSData *)aData
           forGroupByRegEx:(NSRegularExpression *)aGroupByRegEx
            forParseConfig:(NSDictionary *)aParseConfig
{
    NSString *dataString = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    
    NSArray *groupByMatches = [aGroupByRegEx matchesInString:dataString
                                                    options:0
                                                      range:NSMakeRange(0, dataString.length)
                               ];
    
    if ( groupByMatches.count < 1 ) return [NSDictionary dictionary];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for ( int i = 0; i < groupByMatches.count; i++ ) {
        
        NSTextCheckingResult *groupByMatch = [groupByMatches objectAtIndex:i];
        NSString *activeKey = [dataString substringWithRange:[groupByMatch rangeAtIndex:1]];
        NSRange groupByRange = [groupByMatch rangeAtIndex:0];
        
        NSUInteger startLocation = groupByRange.location + groupByRange.length;
        
        NSUInteger endLocation;
        if ( groupByMatches.count == i + 1 ) {
            endLocation = dataString.length;
        } else {
            endLocation = [[groupByMatches objectAtIndex:i+1] rangeAtIndex:0].location;
        }

        NSString *elementsStr = [dataString substringWithRange:NSMakeRange(startLocation, endLocation - startLocation)];
        [dict setObject:[self parseData:[elementsStr dataUsingEncoding:NSUTF8StringEncoding] forOutputConfig:aParseConfig]
                 forKey:activeKey
         ];
    }

    return dict;
}

-(id)parseDataForSingleCycle:(NSData *)aData forOutputConfig:(NSDictionary *)aParseConfig
{
    NSDictionary *defaultsDict = [aParseConfig objectForKey:@"defaultValues"];
    NSDictionary *matchValues  = [aParseConfig objectForKey:@"matchValues"];
    NSDictionary *captures     = [aParseConfig objectForKey:@"captures"];
    NSString *rawDataString;
    
    BOOL shouldReturnString = NO;

    NSMutableDictionary *onMatchDict = nil;
    if ( defaultsDict || matchValues ) {
        
        onMatchDict = [[NSMutableDictionary alloc] init];
        
        if ( defaultsDict )
            [onMatchDict addEntriesFromDictionary:defaultsDict];
        
        if ( matchValues )
            [onMatchDict addEntriesFromDictionary:matchValues];
    }
    
    NSMutableArray *mutableMatchResults = [NSMutableArray new];
    NSRegularExpression *parsePatternRegEx = [aParseConfig objectForKey:@"_regEx"];
    NSString *xPath = [aParseConfig objectForKey:@"xPath"];
    if ( xPath ) {
        
        TFHpple *parser = [TFHpple hppleWithHTMLData:aData];
        
        NSArray *xPathMatches = [parser searchWithXPathQuery:xPath];
        
        for ( TFHppleElement *topLevelMatchElem in xPathMatches ) {

            NSDictionary *xCaptures = [aParseConfig objectForKey:@"xCaptures"];
            if ( xCaptures ) {
            
                NSMutableDictionary *mutableXCaptureDict = [NSMutableDictionary new];
                for ( NSString *xCaptureKey in xCaptures.allKeys ) {
                
                    XCapture *xCapture = [xCaptures objectForKey:xCaptureKey];
                    
                    TFHppleElement *elem = topLevelMatchElem;
                    
                    NSString *textResult = nil;
                    for ( HppleOp *op in xCapture.hppleOps ) {
                        
                        if ( [op.func isEqualToString:@"CHILD"] ) {
                            
                            NSArray *filteredElems;

                            id name = [op.params objectAtIndex:0];
                            if ( [name isKindOfClass:[NSString class]] ) {
                                
                                filteredElems = [elem.children filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tagName like %@", name]];
                                
                            } else {
                                
                                //name is NSNull
                                filteredElems = [elem.children filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"not tagName like %@", @"text"]];
                            }
                            
                            NSUInteger index;
                            id rawIndex = [op.params objectAtIndex:1];
                            if ( [rawIndex isKindOfClass:[NSString class]] ) {
                                index = [rawIndex integerValue];
                            } else {
                                //index is NSNull
                                index = 1;
                            }
                            
                            if ( index-1 < filteredElems.count ) {
                                elem = filteredElems[index-1];
                            } else {
                                break;
                            }
                        
                        } else if ( [op.func isEqualToString:@"ATTR"] ) {
                            
                            textResult = [elem.attributes objectForKey:[op.params objectAtIndex:0]];
                            break;

                        } else if ( [op.func isEqualToString:@"CONTENT"] ) {
                            
                            textResult = elem.content;
                            break;
                            
                        } else if ( [op.func isEqualToString:@"TEXT"] ) {

                            textResult = elem.text;
                            break;
                        }
                    }

                    NSString *filteredTextResult;
                    if ( textResult ) {

                        NSTextCheckingResult *match = [xCapture.filter firstMatchInString:textResult
                                                                                  options:0
                                                                                    range:NSMakeRange(0, textResult.length)
                                                       ];
                        
                        if ( match ) {
                            NSRange range = [match rangeAtIndex:1];
                            if ( range.location != NSNotFound )
                                filteredTextResult = [textResult substringWithRange:range];
                        }
                    }
                    
                    if ( !filteredTextResult )
                        continue;
                    
                    [mutableXCaptureDict setObject:filteredTextResult forKey:xCaptureKey];
                }
                
                [mutableMatchResults addObject:[NSDictionary dictionaryWithDictionary:mutableXCaptureDict]];
                
            } else {
                
                if ( !( onMatchDict || captures ) )
                    shouldReturnString = YES;
                
                TFHppleElement *elem = topLevelMatchElem;
                NSString *text = elem.text;
        
                if ( text ) {
                    
                    NSTextCheckingResult *match = [parsePatternRegEx firstMatchInString:text
                                                                                options:0
                                                                                  range:NSMakeRange(0, text.length)
                                                   ];

                    if ( match ) {
                        
                        if ( onMatchDict || captures ) {

                            id result = [self buildResultForMatch:match
                                                   withDataString:text
                                               withCapturesConfig:captures
                                                    startWithDict:onMatchDict
                                         ];
                        
                            [mutableMatchResults addObject:result];
                            
                        } else {
                            
                            [mutableMatchResults addObject:[text substringWithRange:[match rangeAtIndex:1]]];
                        }
                    }
                }
            }
        }
        
    } else {

        rawDataString = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    }
    
    if ( rawDataString ) {
    
        NSArray *rawPatternMatches = [parsePatternRegEx matchesInString:rawDataString
                                                                options:0
                                                                  range:NSMakeRange(0, rawDataString.length)

                                      ];
        
        if ( !( onMatchDict || captures ) )
            shouldReturnString = YES;
        
        for ( NSTextCheckingResult *match in rawPatternMatches ) {
        
            id result = [self buildResultForMatch:match
                                   withDataString:rawDataString
                               withCapturesConfig:captures
                                    startWithDict:onMatchDict
                         ];
            
            [mutableMatchResults addObject:result];
        }
    }

    NSDictionary *matchesAsArray   = [aParseConfig objectForKey:@"matchesAsArray"];
    NSDictionary *appendingMatches = [aParseConfig objectForKey:@"appendingMatches"];
    NSNumber     *matchIteration   = [aParseConfig objectForKey:@"matchIteration"];

    if ( matchesAsArray ) {
    
        if ( !mutableMatchResults.count ) return @[];
        
        NSInteger startIndex  = [[matchesAsArray objectForKey:@"startIndex"] integerValue];
        NSInteger endIndex    = [[matchesAsArray objectForKey:@"endIndex"] integerValue];
        
        NSMutableArray *finalResults = [[NSMutableArray alloc] init];
        for ( int i = 0; i < mutableMatchResults.count; i++ ) {
            
            if ( i < startIndex ) continue;
            if ( endIndex > 0 && i >= endIndex ) break;
            
            [finalResults addObject:[mutableMatchResults objectAtIndex:i]];
        }
             
        return [NSArray arrayWithArray:finalResults];
    
    } else if ( appendingMatches ) {

        if ( !mutableMatchResults.count )
            return @{};
        
        NSUInteger startIndex = [[appendingMatches objectForKey:@"startIndex"] integerValue];
        NSUInteger endIndex   = [[appendingMatches objectForKey:@"endIndex"] integerValue];
        
        NSString *joinWith = [appendingMatches objectForKey:@"joinWith"];
        if ( !joinWith )
            joinWith = @"";
        
        NSDictionary *keysToAppend = [appendingMatches objectForKey:@"append"];
        
        NSMutableDictionary *appendedDict = [NSMutableDictionary new];
        for ( int i = 0; i < mutableMatchResults.count; i++ ) {
            
            if ( i < startIndex ) continue;
            if ( endIndex > 0 && i >= endIndex ) break;

            NSDictionary *appendDict = [mutableMatchResults objectAtIndex:i];
            
            for ( NSString *key in appendDict.allKeys ) {
                
                NSString *val = [appendDict objectForKey:key];
                
                if ( [keysToAppend objectForKey:key] ) {
                    
                    NSString *existingStr = [appendedDict objectForKey:key];
                    if ( existingStr ) {
                        
                        NSString *appendedStr = [existingStr stringByAppendingFormat:@"%@%@", joinWith, val];
                        [appendedDict setObject:appendedStr forKey:key];
                        
                    } else {
                        
                        [appendedDict setObject:val forKey:key];
                    }
                    
                } else {
                    
                    [appendedDict setObject:val forKey:key];
                }
            }
        }
    
        return [NSDictionary dictionaryWithDictionary:appendedDict];
        
    } else {
        
        // matchIteration
        NSUInteger matchIndex = [matchIteration integerValue] - 1;
        
        if ( matchIndex >= mutableMatchResults.count ) {
            if ( shouldReturnString == YES ) {
                return @"";
            } else if ( defaultsDict ) {
                return defaultsDict;
            } else {
                return @{};
            }
        }

        return [mutableMatchResults objectAtIndex:matchIndex];
    }
}

-(id)buildResultForMatch:(NSTextCheckingResult *)aMatch
          withDataString:(NSString *)aDataString
      withCapturesConfig:(NSDictionary *)aCapturesConfig
           startWithDict:(NSDictionary *)aStartWithDict
{
    if ( aCapturesConfig || aStartWithDict ) {
    
        NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
        if ( aStartWithDict )
            [resultDict addEntriesFromDictionary:aStartWithDict];
        
        for ( NSString *key in aCapturesConfig.allKeys ) {
        
            NSInteger captureIndex = [[aCapturesConfig objectForKey:key] integerValue];
        
            NSRange captureRange = [aMatch rangeAtIndex:captureIndex];
            NSString *captureStr = ( captureRange.length > 0 ) ? [aDataString substringWithRange:captureRange] : @"";

            [resultDict setObject:captureStr forKey:key];
        }

        return [NSDictionary dictionaryWithDictionary:resultDict];
        
    } else {
        
        NSRange captureRange = [aMatch rangeAtIndex:1];
        return ( captureRange.length > 0 ) ? [aDataString substringWithRange:captureRange] : @"";
    }
}

-(NSString *)buildVariableStr:(id)aVarRaw
           withInputVariables:(NSDictionary *)aInputVars
                 withPathDesc:(NSString *)aPathDesc
{
    if ( [aVarRaw isKindOfClass:[NSString class]] ) {
        
        return [aInputVars objectForKey:aVarRaw];
        
    } else if ( [aVarRaw isKindOfClass:[NSDictionary class]] ) {
        
        if ( [[aVarRaw objectForKey:@"type"] isEqualToString:@"date"] ) {
            
            long totalOffset = 0;
            
            NSNumber *dayOffset;
            if ( ( dayOffset = [aVarRaw objectForKey:@"dayOffset"] ) ) {
                totalOffset += 24 * 60 * 60 * dayOffset.floatValue;
            }
            
            NSNumber *secondOffset;
            if ( ( secondOffset = [aVarRaw objectForKey:@"secondOffset"] ) ) {
                totalOffset += secondOffset.floatValue;
            }
            
            NSDate *initDate, *dateVariableName;
            if ( ( dateVariableName = [aVarRaw objectForKey:@"useDateFromVariable"] ) ) {
                
                initDate = [aInputVars objectForKey:dateVariableName];
                if ( !initDate )
                    [NSException raise:kExceptionWebAbstractRuntime
                                format:@"useDateFromVariable '%@' not found in variables for %@", dateVariableName, aPathDesc
                     ];
                
            } else {
                
                initDate = [NSDate date];
            }
            
            NSDate *date = [NSDate dateWithTimeInterval:totalOffset sinceDate:initDate];
            
            static NSCalendar *calendar;
            if ( !calendar ) {
                calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            }
            
            NSDateComponents *c = [calendar components:  NSEraCalendarUnit
                                   | NSYearCalendarUnit
                                   | NSMonthCalendarUnit
                                   | NSDayCalendarUnit
                                   | NSHourCalendarUnit
                                   | NSMinuteCalendarUnit
                                   | NSSecondCalendarUnit
                                   | NSWeekCalendarUnit
                                   | NSWeekdayCalendarUnit
                                   | NSWeekdayOrdinalCalendarUnit
                                   | NSQuarterCalendarUnit
                                   | NSWeekOfMonthCalendarUnit
                                   | NSWeekOfYearCalendarUnit
                                   | NSYearForWeekOfYearCalendarUnit
                                   | NSCalendarCalendarUnit
                                   | NSTimeZoneCalendarUnit
                                              fromDate:date
                                   ];
            
            NSMutableArray *varValues = [[NSMutableArray alloc] initWithCapacity:10];
            
            for ( NSString *dateComponent in [aVarRaw objectForKey:@"dateVariables"] ) {
                if ( [dateComponent isEqualToString:@"era"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.era]];
                } else if ( [dateComponent isEqualToString:@"year"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.year]];
                } else if ( [dateComponent isEqualToString:@"twoDigitYear"] ) {
                    [varValues addObject:[NSNumber numberWithInt:(int)(c.year % 100)]];
                } else if ( [dateComponent isEqualToString:@"month"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.month]];
                } else if ( [dateComponent isEqualToString:@"day"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.day]];
                } else if ( [dateComponent isEqualToString:@"hour"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.hour]];
                } else if ( [dateComponent isEqualToString:@"minute"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.minute]];
                } else if ( [dateComponent isEqualToString:@"second"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.second]];
                } else if ( [dateComponent isEqualToString:@"week"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.week]];
                } else if ( [dateComponent isEqualToString:@"weekday"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.weekday]];
                } else if ( [dateComponent isEqualToString:@"weekdayOrdinal"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.weekdayOrdinal]];
                } else if ( [dateComponent isEqualToString:@"quarter"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.quarter]];
                } else if ( [dateComponent isEqualToString:@"weekOfMonth"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.weekOfMonth]];
                } else if ( [dateComponent isEqualToString:@"weekOfYear"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.weekOfYear]];
                } else if ( [dateComponent isEqualToString:@"yearForWeekOfYear"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.yearForWeekOfYear]];
                }
            }
            
            while ( varValues.count < 10 ) {
                [varValues addObject:[NSString string]];
            }
            
            NSString *dateStr = [NSString stringWithFormat:[aVarRaw objectForKey:@"dateFormat"] ,[[varValues objectAtIndex:0] integerValue]
                                 ,[[varValues objectAtIndex:1] integerValue]
                                 ,[[varValues objectAtIndex:2] integerValue]
                                 ,[[varValues objectAtIndex:3] integerValue]
                                 ,[[varValues objectAtIndex:4] integerValue]
                                 ,[[varValues objectAtIndex:5] integerValue]
                                 ,[[varValues objectAtIndex:6] integerValue]
                                 ,[[varValues objectAtIndex:7] integerValue]
                                 ,[[varValues objectAtIndex:8] integerValue]
                                 ,[[varValues objectAtIndex:9] integerValue]
                                 ];
            return dateStr;
        }
    }
    
    return nil; //never reached
}


@end
