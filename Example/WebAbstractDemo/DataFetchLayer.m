//
//  DataFetchLayer.m
//  WebAbstractDemo
//
//  Created by Eric Colton on 4/23/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "DataFetchLayer.h"



static NSDictionary *resourcePathMap;

@implementation DataFetchLayer

+(void)initialize {

    resourcePathMap = @{ @"/test/index.html"  : @"webAbstractTest"
                        ,@"workout"           : @"workout"
//                      ,@"/cgi-bin/test.cgi" : @"testcgi"
                        ,@"/cgi-bin/date_string_test.cgi" : @"testcgi"
                       };
}

+(NSData *)sendSynchronousRequest:(NSURLRequest *)aURLRequest
                returningResponse:(NSURLResponse *__autoreleasing *)aURLResponse
                            error:(NSError *__autoreleasing *)aError
{
    if ( DATA_FETCH_USES_LIVE_WEB_RESULTS ) {

        //
        // Actually do a web request
        //
        return [NSURLConnection sendSynchronousRequest:aURLRequest
                                     returningResponse:aURLResponse
                                                 error:aError
                ];
        
    } else {
        
        //
        // Don't go to network; use test data
        //
        NSString *filename = resourcePathMap[aURLRequest.URL.path];
        if ( filename ) {
            
            NSError *error;
            NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"txt"];
            NSString *contents = [NSString stringWithContentsOfFile:path
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error
                                  ];

            return [contents dataUsingEncoding:NSUTF8StringEncoding];

        } else {
            
            return nil;
        }
    }
}

@end
