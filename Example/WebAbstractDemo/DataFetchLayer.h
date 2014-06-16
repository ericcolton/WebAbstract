//
//  DataFetchLayer.h
//  DataAbstractDemo
//
//  Created by Eric Colton on 4/23/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DATA_FETCH_USES_LIVE_WEB_RESULTS NO

#define kExceptionDataFetchFailure @"DATA FETCH FAILURE"

@interface DataFetchLayer : NSObject

+(NSData *)sendSynchronousRequest:(NSURLRequest *)aURLRequest
                returningResponse:(NSURLResponse *__autoreleasing *)aURLResponse
                            error:(NSError *__autoreleasing *)aError;

@end
