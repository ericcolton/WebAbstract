//
//  TestTableViewController.m
//  WebAbstractDemo
//
//  Created by ERIC COLTON on 6/4/14.
//  Copyright (c) 2014 Cindy Software. All rights reserved.
//

#import "TestTableViewController.h"
#import "WebAbstract.h"
#import "WebAbstractConfig.h"
#import "DataFetchLayer.h"


@interface TestTableViewController ()
{
    NSMutableArray *dataResults;
}
@end

@implementation TestTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        dataResults = [NSMutableArray new];
        self.tableView.allowsSelection = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self popuateDataResults];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////
#pragma mark instance methods (private)
////
-(void)popuateDataResults
{
    WebAbstractConfig *webAbstractTestConfig = [[WebAbstractConfig alloc] initWithBundledPlist:@"WebAbstractConfig_test_driver"];
    
    WebAbstract *webAbstractTest = [[WebAbstract alloc] initWithConfig:webAbstractTestConfig];
    
    //
    //example of how to set a hard url prefix, which would be used if DataFetchLayer was using live web data
    //
    [webAbstractTest setUrlHardPrefix:@"www.webabstract.org"];
    
    NSURLRequest *urlRequest = [webAbstractTest buildUrlRequestForOperation:@"WebAbstractTest"
                                                               forSourceTag:@"WebAbstractTest"
                                                              withVariables:@{ @"relativeUrl" : @"index" }
                                ];
    
    NSURLResponse *response;
    NSError *error;
    NSData *htmlData = [DataFetchLayer sendSynchronousRequest:urlRequest
                                            returningResponse:&response
                                                        error:&error
                        ];
    
    if ( error )
        [NSException raise:kExceptionDataFetchFailure
                    format:@"Unable to execute 'WebAbstractTest' url request. ERROR: %@", [error localizedDescription]
         ];
    
    NSString *xPathTest = [webAbstractTest parseData:htmlData
                                        forOperation:@"WebAbstractTest"
                                        forOutputTag:@"xPathTest"
                           ];
    
    [dataResults addObject:@[@"xPath test", @"Koala", xPathTest]];
//    NSLog(@"String for key 'animal' in xPath test: %@", xPathTest);
    
    NSDictionary *xPathWithXCapturesTest = [webAbstractTest parseData:htmlData
                                                         forOperation:@"WebAbstractTest"
                                                         forOutputTag:@"xPathWithXCapturesTest"
                                            ];

    NSString *resultString = [NSString stringWithFormat:@"content = %@, id = %@", xPathWithXCapturesTest[@"content"], xPathWithXCapturesTest[@"id"]];
    
    [dataResults addObject:@[@"xPath with captures", @"content = Big, id = 1", resultString]];
    
//    NSLog(@"Dictionary for key 'animal' in xPathWithXCaptures test: %@", xPathWithXCapturesTest);
    
    NSString *xPathWithPatternTest = [webAbstractTest parseData:htmlData
                                                   forOperation:@"WebAbstractTest"
                                                   forOutputTag:@"xPathWithPatternTest"
                                      ];
    
    [dataResults addObject:@[@"xPath with pattern", @"fox", xPathWithPatternTest]];
    
//    NSLog(@"String for key 'animal' in xPathWithPattern test: %@", xPathWithPatternTest);
    
    NSDictionary *xPathWithPatternAndCapturesTest = [webAbstractTest parseData:htmlData
                                                                  forOperation:@"WebAbstractTest"
                                                                  forOutputTag:@"xPathWithPatternAndCapturesTest"
                                                     ];

    resultString = [NSString stringWithFormat:@"subject1 = %@, subject2 = %@", xPathWithPatternAndCapturesTest[@"subject1"], xPathWithPatternAndCapturesTest[@"subject2"]];
    
    [dataResults addObject:@[@"xPath with pattern and captures", @"subject1 = fox, subject2 = dog", resultString]];
    
//    NSLog(@"String for key 'animal2' in xPathWithPatternAndCaptures test: %@", [xPathWithPatternAndCapturesTest objectForKey:@"subject2"]);
    
    NSDictionary *patternTest = [webAbstractTest parseData:htmlData
                                              forOperation:@"WebAbstractTest"
                                              forOutputTag:@"patternTest"
                                 ];
 
    [dataResults addObject:@[@"pattern", @"fox", patternTest]];
//    NSLog(@"String for key 'animal' in pattern test: %@", patternTest);
    

    NSDictionary *patternWithCapturesTest = [webAbstractTest parseData:htmlData
                                                          forOperation:@"WebAbstractTest"
                                                          forOutputTag:@"patternWithCapturesTest"
                                             ];
    
    [dataResults addObject:@[@"pattern with captures, key 'animal'", @"fox", [patternWithCapturesTest objectForKey:@"animal"]]];
    
//    NSLog(@"String for key 'animal' in patternWithCaptures test: %@",

    NSDictionary *matchIterationTest = [webAbstractTest parseData:htmlData
                                                     forOperation:@"WebAbstractTest"
                                                     forOutputTag:@"parseTest_with_matchIteration"
                                        ];
    
    [dataResults addObject:@[@"parse with matchIteration, key 'otherAnimal'", @"cat", [matchIterationTest objectForKey:@"otherAnimal"]]];
//    NSLog(@"String for key 'otherAnimal' for parseTest_with_matchIteration test: %@", [matchIterationTest objectForKey:@"otherAnimal"]);
    
    NSArray *matchesAsArrayTest = [webAbstractTest parseData:htmlData
                                                forOperation:@"WebAbstractTest"
                                                forOutputTag:@"parseTest_with_matchesAsArray"
                                   ];

    NSArray *correctAnswersArray = @[@"lizard", @"cat", @"penguin", @"deer"];
    for ( int i = 0; i < matchesAsArrayTest.count; i++ ) {
        
        NSDictionary *entry = matchesAsArrayTest[i];

        NSString *name = [NSString stringWithFormat:@"parse with matchesAsArray row %d, key 'otherAnimal'", i];
        [dataResults addObject:@[name, correctAnswersArray[i], entry[@"otherAnimal"]]];
        
//        NSLog(@"String for key 'otherAnimal' for parseTest_with_matchesAsArray test: %@", [entry objectForKey:@"otherAnimal"]);
    }
    
    NSDictionary *appendingMatchesTest = [webAbstractTest parseData:htmlData
                                                       forOperation:@"WebAbstractTest"
                                                       forOutputTag:@"parseTest_with_appendingMatches"
                                          ];

    [dataResults addObject:@[@"parse with appendingMatches", @"queer, quicker, quickster, quiet", appendingMatchesTest[@"animalAdjective"]]];
    
//     NSLog(@"String for key 'animalAdjective' for parseTest_with_appendingMatches test: %@", [appendingMatchesTest objectForKey:@"animalAdjective"]);
    
    NSDictionary *eachGroupTest = [webAbstractTest parseData:htmlData
                                                forOperation:@"WebAbstractTest"
                                                forOutputTag:@"eachGroupTest"
                                   ];
    
    NSDictionary *correctAnswersMap = @{ @"1/1/2000" : @"queer"
                                        ,@"1/1/2001" : @"quicker"
                                        ,@"1/1/1803" : @"quiet"
                                        ,@"1/1/2002" : @"quickster"
                                        ,@"1/1/1900" : @"queer"
                                        ,@"1/1/2003" : @"quiet"
                                        ,@"1/1/1901" : @"quicker"
                                        ,@"1/1/1800" : @"queer"
                                        ,@"1/1/1902" : @"quickster"
                                        ,@"1/1/1801" : @"quicker"
                                        ,@"1/1/1903" : @"quiet"
                                        ,@"1/1/1802" : @"quickster"
                                       };
    
    for ( NSString *key in eachGroupTest.allKeys ) {
        
        NSDictionary *val = eachGroupTest[key][@"animalAdjective"];
        NSString *str = [NSString stringWithFormat:@"eachGroup value for key 'animalAdjective' for grouping '%@'", key];
        
        [dataResults addObject:@[str, correctAnswersMap[key], val]];
//        NSLog(@"String for key 'animalAdjective' for eachGroupTest test: %@ => %@", key, [val objectForKey:@"animalAdjective"]);
    }

    correctAnswersMap = @{ @"Client 1" : @{ @"1/1/1802" : @"quickster"
                                           ,@"1/1/1801" : @"quicker"
                                           ,@"1/1/1800" : @"queer"
                                           ,@"1/1/1803" : @"quiet"
                                          }
                          ,@"Client 2" : @{ @"1/1/1901" : @"quicker"
                                           ,@"1/1/1900" : @"queer"
                                           ,@"1/1/1903" : @"quiet"
                                           ,@"1/1/1902" : @"quickster"
                                          }
                          ,@"Client 3" : @{ @"1/1/2001" : @"quicker"
                                           ,@"1/1/2000" : @"queer"
                                           ,@"1/1/2003" : @"quiet"
                                           ,@"1/1/2002" : @"quickster"
                                          }
                         };
                           
    NSDictionary *eachGroupNestedTest = [webAbstractTest parseData:htmlData
                                                      forOperation:@"WebAbstractTest"
                                                      forOutputTag:@"eachGroupNestedTest"
                                         ];
    
    for ( NSString *key1 in eachGroupNestedTest.allKeys ) {
        
        NSDictionary *val = [eachGroupNestedTest objectForKey:key1];
        
        for ( NSString *key2 in val.allKeys ) {
            
            NSDictionary *animalAdjective = [[val objectForKey:key2] objectForKey:@"animalAdjective"];
            //NSLog(@"String for key 'animalAdjective' for eachGroupNestedTest test: %@ => %@ => %@", key1, key2, animalAdjective);
            
            NSString *str = [NSString stringWithFormat:@"eachGroupNeseted entry for key 'animalAdjective' for nested grouping [%@][%@]", key1, key2];
            [dataResults addObject:@[str, correctAnswersMap[key1][key2], animalAdjective]];
        }
    }
    
    NSDictionary *defaultValuesTest_1 = [webAbstractTest parseData:htmlData
                                                      forOperation:@"WebAbstractTest"
                                                      forOutputTag:@"defaultValuesTest_1"
                                         ];
    
//    for ( NSString *key in defaultValuesTest_1.allKeys ) {
//        NSDictionary *val = [defaultValuesTest_1 objectForKey:key];
        //NSLog(@"String for key '%@' for defaultValuesTest_1 test: %@", key, val);
        
        [dataResults addObject:@[@"default value for key 'default_one'", @"got default_one value!", defaultValuesTest_1[@"default_one"]]];
//    }
    
    NSDictionary *defaultValuesTest_2 = [webAbstractTest parseData:htmlData
                                                      forOperation:@"WebAbstractTest"
                                                      forOutputTag:@"defaultValuesTest_2"
                                         ];

    correctAnswersMap = @{ @"match_two"   : @"got match_two value!"
                          ,@"default_two" : @"got default_two value!"
                         };
    
    for ( NSString *key in defaultValuesTest_2.allKeys ) {
        NSDictionary *val = defaultValuesTest_2[key];
//        NSLog(@"String for key '%@' for defaultValuesTest_2 test: %@", key, val);
        
        NSString *str = [NSString stringWithFormat:@"dafault value for key '%@", key];
        [dataResults addObject:@[str, correctAnswersMap[key], val]];
    }
    
    NSArray *parseCyclesTest = [webAbstractTest parseData:htmlData
                                             forOperation:@"WebAbstractTest"
                                             forOutputTag:@"parseCyclesTest"
                                ];
    
    correctAnswersArray = @[ @{ @"date" : @"1/1/1900" }
                            ,@{ @"date" : @"1/1/1901" }
                           ];
    for ( int i = 0; i < parseCyclesTest.count; i++ ) {
        NSDictionary *entry = parseCyclesTest[i];
        for ( NSString *key in entry.allKeys ) {
            NSString *val = entry[key];
//            NSLog(@"String for key '%@' for parseCyclesTest test [CYCLE %d]: %@", key, i, val);
            
            NSString *str = [NSString stringWithFormat:@"parseCycles cycle %d", i];
            [dataResults addObject:@[str, correctAnswersArray[i][@"date"], val]];
        }
    }
    
    NSDictionary *parseCyclesUntilSuccessTest = [webAbstractTest parseData:htmlData
                                                              forOperation:@"WebAbstractTest"
                                                              forOutputTag:@"parseCyclesUntilSuccessTest"
                                                 ];

    correctAnswersMap = @{ @"date" : @"1/1/2002" };
    
    for ( NSString *key in parseCyclesUntilSuccessTest.allKeys ) {
        NSString *val = [parseCyclesUntilSuccessTest objectForKey:key];
//        NSLog(@"String for key '%@' for parseCyclesUntilSuccessTest test: %@", key, val);

        NSString *str = [NSString stringWithFormat:@"parseCyclesUntilSuccess for key '%@'", key];
        [dataResults addObject:@[str, correctAnswersMap[key], val]];
    }
    
    NSDictionary *parseCyclesMergeKeysTest = [webAbstractTest parseData:htmlData
                                                           forOperation:@"WebAbstractTest"
                                                           forOutputTag:@"parseCyclesMergeKeysTest"
                                              ];

    correctAnswersMap = @{ @"the_year"  : @"1997"
                          ,@"the_model" : @"Accord"
                          ,@"the_color" : @"Red"
                          ,@"the_make"  : @"Honda"
                         };
    for ( NSString *key in parseCyclesMergeKeysTest.allKeys ) {
        NSString *val = [parseCyclesMergeKeysTest objectForKey:key];
        
//        NSLog(@"String for key '%@' for parseCyclesMergeKeysTest test: %@", key, val);
        
        NSString *str = [NSString stringWithFormat:@"parseCyclesMergeKeys for key '%@'", key];
        [dataResults addObject:@[str, correctAnswersMap[key], val]];
    }

    /*
     * urlTests
     */
    NSString *dateString;
    if ( DATA_FETCH_USES_LIVE_WEB_RESULTS ) {
        
        static NSDateFormatter *df = nil;
        if ( !df ) {
            df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyyMMdd"];
        }

        dateString = [df stringFromDate:[NSDate date]];
        
    } else {
        
        dateString = @"20140502";
    }
    
    urlRequest = [webAbstractTest buildUrlRequestForOperation:@"urlTests"
                                                 forSourceTag:@"urlTodayTest"
                                                withVariables:@{ @"yyyymmdd_date" : dateString }
                  ];
    
    htmlData = [DataFetchLayer sendSynchronousRequest:urlRequest
                                    returningResponse:&response
                                                error:&error
                ];
    
    if ( error )
        [NSException raise:kExceptionDataFetchFailure
                    format:@"Unable to execute 'WebAbstractTest' url request. ERROR: %@", [error localizedDescription]
         ];
    
    NSDictionary *urlTest = [webAbstractTest parseData:htmlData
                                          forOperation:@"urlTests"
                                          forOutputTag:@"urlTests"
                             ];

    
//    NSLog(@"String for key 'dayOfWeek' for urlTodayTest test: %@", urlTest); //[@"dayOfWeek"]);
    
    [dataResults addObject:@[@"URLRequest construction with yyyymmdd_date", @"Thursday", urlTest[@"dayOfWeek"]]];
    
    urlRequest = [webAbstractTest buildUrlRequestForOperation:@"urlTests"
                                                 forSourceTag:@"urlTomorrowTest"
                                                withVariables:@{ @"input_nsdate" : [NSDate date] }
                  ];
    
    htmlData = [DataFetchLayer sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if ( error )
        [NSException raise:kExceptionDataFetchFailure
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
    
    htmlData = [DataFetchLayer sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if ( error )
        [NSException raise:kExceptionDataFetchFailure
                    format:@"Unable to execute 'WebAbstractTest' url request. ERROR: %@", [error localizedDescription]
         ];
    
    urlTest = [webAbstractTest parseData:htmlData
                            forOperation:@"urlTests"
                            forOutputTag:@"urlTests"
               ];
    
    NSLog(@"String for key 'dayOfWeek' for urlYesterdayTest test: %@", [urlTest objectForKey:@"dayOfWeek"]);
    
    /*
     *
     * httpPostTest
     *
     */
    urlRequest = [webAbstractTest buildUrlRequestForOperation:@"httpPostTest"
                                                 forSourceTag:@"httpPostTest"
                                                withVariables:@{ @"dynamicVar1" : @"Foo"
                                                                ,@"dynamicVar2" : @"Bar"
                                                               }
                  ];
    
    htmlData = [DataFetchLayer sendSynchronousRequest:urlRequest
                                    returningResponse:&response
                                                error:&error
                ];
    
    if ( error )
        [NSException raise:kExceptionDataFetchFailure
                    format:@"Unable to execute 'WebAbstractTest' url request. ERROR: %@", [error localizedDescription]
         ];
    
    urlTest = [webAbstractTest parseData:htmlData
                            forOperation:@"httpPostTest"
                            forOutputTag:@"httpPostTest"
               ];
    
    NSLog(@"String for key 'dynamicVar1' for httpPostTest test: %@", urlTest);
    
    NSLog(@"RESULTS: %@", dataResults);
    return;
}

////
#pragma mark UITableViewDataSource
////
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    return 10;
    return dataResults.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"WebAbstractDemo Tests";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseID = @"UITableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if ( !cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseID];
    }

    NSArray *rowData = dataResults[indexPath.row];
    NSString *testDesc = rowData[0];
    NSString *correct  = rowData[1];
    NSString *parsed   = rowData[2];
    
    cell.textLabel.text = testDesc;
    
    NSString *testResult = ( [correct isEqualToString:parsed] ) ? @"👍" : @"😬";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ == %@", testResult, correct, parsed];

    return cell;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
