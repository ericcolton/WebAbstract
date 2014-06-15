//
//  AppDelegate.m
//  WebAbstractDemo
//
//  Created by Eric Colton on 3/2/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "AppDelegate.h"
#import "TestTableViewController.h"
#import "WebAbstract.h"

//#import "WebFetchLayer.h"



@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    TestTableViewController *tvc = [TestTableViewController new];
    [self.window setRootViewController:tvc];
    [self.window makeKeyAndVisible];
    
    return YES;
}

/*
    
    WebAbstractConfig *webAbstractTestConfig = [[WebAbstractConfig alloc] initWithBundledPlist:@"WebAbstractConfig_test_driver"];
    
    WebAbstract *webAbstractTest = [[WebAbstract alloc] initWithConfig:webAbstractTestConfig];

    [webAbstractTest setUrlHardPrefix:@"www.webabstract.org"];

    NSURLRequest *urlRequest = [webAbstractTest buildUrlRequestForOperation:@"WebAbstractTest"
                                                               forSourceTag:@"WebAbstractTest"
                                                              withVariables:@{ @"relativeUrl" : @"index" }
                                ];
    
    NSURLResponse *response;
    NSError *error;
    NSData *htmlData = [WebFetchLayer sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if ( error )
        [NSException raise:kExceptionWebFetchFailure
                    format:@"Unable to execute 'WebAbstractTest' url request. ERROR: %@", [error localizedDescription]
         ];
    
    NSString *xPathTest = [webAbstractTest parseData:htmlData
                                        forOperation:@"WebAbstractTest"
                                        forOutputTag:@"xPathTest"
                           ];

    NSLog(@"String for key 'animal' in xPath test: %@", xPathTest);
    
    NSDictionary *xPathWithXCapturesTest = [webAbstractTest parseData:htmlData
                                                         forOperation:@"WebAbstractTest"
                                                         forOutputTag:@"xPathWithXCapturesTest"
                                            ];
    
    NSLog(@"Dictionary for key 'animal' in xPathWithXCaptures test: %@", xPathWithXCapturesTest);
    
    NSString *xPathWithPatternTest = [webAbstractTest parseData:htmlData
                                                   forOperation:@"WebAbstractTest"
                                                   forOutputTag:@"xPathWithPatternTest"
                                      ];
    
    NSLog(@"String for key 'animal' in xPathWithPattern test: %@", xPathWithPatternTest);
    
    NSDictionary *xPathWithPatternAndCapturesTest = [webAbstractTest parseData:htmlData
                                                                  forOperation:@"WebAbstractTest"
                                                                  forOutputTag:@"xPathWithPatternAndCapturesTest"
                                                     ];
    
    NSLog(@"String for key 'animal2' in xPathWithPatternAndCaptures test: %@", [xPathWithPatternAndCapturesTest objectForKey:@"subject2"]);
    
    NSDictionary *patternTest = [webAbstractTest parseData:htmlData
                                              forOperation:@"WebAbstractTest"
                                              forOutputTag:@"patternTest"
                                 ];
    
    NSLog(@"String for key 'animal' in pattern test: %@", patternTest);
    
    NSDictionary *patternWithCapturesTest = [webAbstractTest parseData:htmlData
                                                          forOperation:@"WebAbstractTest"
                                                          forOutputTag:@"patternWithCapturesTest"
                                             ];
    
    NSLog(@"String for key 'animal' in patternWithCaptures test: %@", [patternWithCapturesTest objectForKey:@"animal"]);
    
    NSDictionary *matchIterationTest = [webAbstractTest parseData:htmlData
                                                     forOperation:@"WebAbstractTest"
                                                     forOutputTag:@"parseTest_with_matchIteration"
                                        ];
    
    NSLog(@"String for key 'otherAnimal' for parseTest_with_matchIteration test: %@", [matchIterationTest objectForKey:@"otherAnimal"]);
    
    NSArray *matchesAsArrayTest = [webAbstractTest parseData:htmlData
                                                forOperation:@"WebAbstractTest"
                                                forOutputTag:@"parseTest_with_matchesAsArray"
                                   ];
    
    for ( NSDictionary *entry in matchesAsArrayTest ) {
        NSLog(@"String for key 'otherAnimal' for parseTest_with_matchesAsArray test: %@", [entry objectForKey:@"otherAnimal"]);
    }
    
    NSDictionary *appendingMatchesTest = [webAbstractTest parseData:htmlData
                                                       forOperation:@"WebAbstractTest"
                                                       forOutputTag:@"parseTest_with_appendingMatches"
                                          ];
    
    NSLog(@"String for key 'animalAdjective' for parseTest_with_appendingMatches test: %@", [appendingMatchesTest objectForKey:@"animalAdjective"]);
    
    NSDictionary *eachGroupTest = [webAbstractTest parseData:htmlData
                                                forOperation:@"WebAbstractTest"
                                                forOutputTag:@"eachGroupTest"
                                   ];

    for ( NSString *key in eachGroupTest.allKeys ) {
        NSDictionary *val = [eachGroupTest objectForKey:key];
        NSLog(@"String for key 'animalAdjective' for eachGroupTest test: %@ => %@", key, [val objectForKey:@"animalAdjective"]);
    }

    NSDictionary *eachGroupNestedTest = [webAbstractTest parseData:htmlData
                                                      forOperation:@"WebAbstractTest"
                                                      forOutputTag:@"eachGroupNestedTest"
                                         ];

    for ( NSString *key1 in eachGroupNestedTest.allKeys ) {
        
        NSDictionary *val = [eachGroupNestedTest objectForKey:key1];
        
        for ( NSString *key2 in val.allKeys ) {
            
            NSDictionary *animalAdjective = [[val objectForKey:key2] objectForKey:@"animalAdjective"];
            NSLog(@"String for key 'animalAdjective' for eachGroupNestedTest test: %@ => %@ => %@", key1, key2, animalAdjective);
        }
    }
    
    NSDictionary *defaultValuesTest_1 = [webAbstractTest parseData:htmlData
                                                      forOperation:@"WebAbstractTest"
                                                      forOutputTag:@"defaultValuesTest_1"
                                         ];
    
    for ( NSString *key in defaultValuesTest_1.allKeys ) {
        NSDictionary *val = [defaultValuesTest_1 objectForKey:key];
        NSLog(@"String for key '%@' for defaultValuesTest_1 test: %@", key, val);
    }
    
    NSDictionary *defaultValuesTest_2 = [webAbstractTest parseData:htmlData
                                                      forOperation:@"WebAbstractTest"
                                                      forOutputTag:@"defaultValuesTest_2"
                                         ];
    
    for ( NSString *key in defaultValuesTest_2.allKeys ) {
        NSDictionary *val = [defaultValuesTest_2 objectForKey:key];
        NSLog(@"String for key '%@' for defaultValuesTest_2 test: %@", key, val);
    }
    
    NSArray *parseCyclesTest = [webAbstractTest parseData:htmlData
                                             forOperation:@"WebAbstractTest"
                                             forOutputTag:@"parseCyclesTest"
                                ];

    for ( int i = 0; i < parseCyclesTest.count; i++ ) {
        NSDictionary *entry = [parseCyclesTest objectAtIndex:i];
        for ( NSString *key in entry.allKeys ) {
            NSString *val = [entry objectForKey:key];
            NSLog(@"String for key '%@' for parseCyclesTest test [CYCLE %d]: %@", key, i, val);
        }
    }
    
    NSDictionary *parseCyclesUntilSuccessTest = [webAbstractTest parseData:htmlData
                                                              forOperation:@"WebAbstractTest"
                                                              forOutputTag:@"parseCyclesUntilSuccessTest"
                                                 ];

    for ( NSString *key in parseCyclesUntilSuccessTest.allKeys ) {
        NSString *val = [parseCyclesUntilSuccessTest objectForKey:key];
        NSLog(@"String for key '%@' for parseCyclesUntilSuccessTest test: %@", key, val);
    }
    
    NSDictionary *parseCyclesMergeKeysTest = [webAbstractTest parseData:htmlData
                                                           forOperation:@"WebAbstractTest"
                                                           forOutputTag:@"parseCyclesMergeKeysTest"
                                              ];

    for ( NSString *key in parseCyclesMergeKeysTest.allKeys ) {
        NSString *val = [parseCyclesMergeKeysTest objectForKey:key];
        NSLog(@"String for key '%@' for parseCyclesMergeKeysTest test: %@", key, val);
    }
    
 
     *
     * urlTests
     *

    static NSDateFormatter *df = nil;
    if ( !df ) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMMdd"];
    }
    
    NSString *dateString = [df stringFromDate:[NSDate date]];
    
    urlRequest = [webAbstractTest buildUrlRequestForOperation:@"urlTests"
                                                 forSourceTag:@"urlTodayTest"
                                                withVariables:@{ @"yyyymmdd_date" : dateString }
                  ];
    
    htmlData = [WebFetchLayer sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if ( error )
        [NSException raise:kExceptionWebFetchFailure
                    format:@"Unable to execute 'WebAbstractTest' url request. ERROR: %@", [error localizedDescription]
         ];

    NSDictionary *urlTest = [webAbstractTest parseData:htmlData
                                          forOperation:@"urlTests"
                                          forOutputTag:@"urlTests"
                             ];

    NSLog(@"String for key 'dayOfWeek' for urlTodayTest test: %@", [urlTest objectForKey:@"dayOfWeek"]);
    
    urlRequest = [webAbstractTest buildUrlRequestForOperation:@"urlTests"
                                                 forSourceTag:@"urlTomorrowTest"
                                                withVariables:@{ @"input_nsdate" : [NSDate date] }
                  ];
    
    htmlData = [WebFetchLayer sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if ( error )
        [NSException raise:kExceptionWebFetchFailure
                    format:@"Unable to execute 'WebAbstractTest' url request. ERROR: %@", [error localizedDescription]
         ];
    
    urlTest = [webAbstractTest parseData:htmlData
                            forOperation:@"urlTests"
                            forOutputTag:@"urlTests"
               ];

    NSLog(@"String for key 'dayOfWeek' for urlTomorrowTest test: %@", [urlTest objectForKey:@"dayOfWeek"]);
   
    urlRequest = [webAbstractTest buildUrlRequestForOperation:@"urlTests"
                                                 forSourceTag:@"urlYesterdayTest"
                                                withVariables:@{ @"input_nsdate" : [NSDate date] }
                  ];
    
    htmlData = [WebFetchLayer sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if ( error )
        [NSException raise:kExceptionWebFetchFailure
                    format:@"Unable to execute 'WebAbstractTest' url request. ERROR: %@", [error localizedDescription]
         ];
    
    urlTest = [webAbstractTest parseData:htmlData
                            forOperation:@"urlTests"
                            forOutputTag:@"urlTests"
               ];
    
    NSLog(@"String for key 'dayOfWeek' for urlYesterdayTest test: %@", [urlTest objectForKey:@"dayOfWeek"]);
    

     *
     * httpPostTest
     *

    urlRequest = [webAbstractTest buildUrlRequestForOperation:@"httpPostTest"
                                                 forSourceTag:@"httpPostTest"
                                                withVariables:@{ @"dynamicVar1" : @"Foo"
                                                                ,@"dynamicVar2" : @"Bar"
                                                               }
                  ];
    
    htmlData = [WebFetchLayer sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if ( error )
        [NSException raise:kExceptionWebFetchFailure
                    format:@"Unable to execute 'WebAbstractTest' url request. ERROR: %@", [error localizedDescription]
         ];
    
    urlTest = [webAbstractTest parseData:htmlData
                            forOperation:@"httpPostTest"
                            forOutputTag:@"httpPostTest"
               ];
    
    NSLog(@"String for key 'dynamicVar1' for httpPostTest test: %@", urlTest);
    
    return YES;

*/


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
