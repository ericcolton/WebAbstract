//
//  WebAbstract.h
//  Gymclass
//
//  Created by Eric Colton on 12/5/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebAbstractConfig.h"

#define kExceptionWebAbstractSetup   @"WEB-ABSTRACT SETUP ERROR"
#define kExceptionWebAbstractRuntime @"WEB-ABSTRACT RUNTIME ERROR"

@interface WebAbstract : NSObject

/* initialize with configuration */
-(id)initWithConfig:(WebAbstractConfig *)aConfig;
-(id)initWithConfigs:(NSArray *)aConfigs;

-(BOOL)isOperationAvailable:(NSString *)aOperation
               forSourceTag:(NSString *)aSourceTag;

-(BOOL)isOperationAvailable:(NSString *)aOperation
               forOutputTag:(NSString *)aOutputTag;

/* Build a URL string from configuartion */
-(NSMutableURLRequest *)buildUrlRequestForOperation:(NSString *)aOperation
                                       forSourceTag:(NSString *)aSourceTag
                                      withVariables:(NSDictionary *)aVariables;

/* Parse NSData from configuration */
-(id)parseData:(NSData *)aData
  forOperation:(NSString *)aOperation
  forOutputTag:(NSString *)aOutputTag;

-(void)setUrlHardPrefix:(NSString *)aPrefix;

@end
