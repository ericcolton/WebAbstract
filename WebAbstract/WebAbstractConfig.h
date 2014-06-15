//
//  WebAbstractConfig.h
//  Gymclass
//
//  Created by Eric Colton on 2/9/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCapture.h"
#import "HppleOp.h"

#define kExceptionWebAbstractConfigIllegalOp @"WEB-ABSTRACT-CONFIG ILLEGAL OP ERROR"
#define kExceptionWebAbstractConfigValidate  @"WEB-ABSTRACT-CONFIG VALIDATION ERROR"
#define kExceptionWebAbstractConfigNotFound  @"WEB-ABSTRACT-CONFIG NOT FOUND"
#define kExceptionWebAbstractConfigBundle    @"WEB-ABSTRACT-CONFIG BUNDLE ERROR"

@interface WebAbstractConfig : NSObject

@property (nonatomic, strong) NSDictionary *configStruct;
@property (nonatomic, strong) NSURL *url;
@property NSURLRequestCachePolicy cachePolicy;
@property NSTimeInterval timeoutInterval;

+(NSString *)removeCurlyBrackets:(NSString *)aString;
+(NSString *)removeSquareBrackets:(NSString *)aString;

-(id)initWithStruct:(NSDictionary *)aStruct;
-(id)initWithBundledPlist:(NSString *)aPlistName;
-(id)initWithURL:(NSURL *)aUrl;

-(NSDictionary *)fetchConfigForOperation:(NSString *)aOperation forSourceTag:(NSString *)aSourceTag;
-(NSDictionary *)fetchConfigForOperation:(NSString *)aOperation forOutputTag:(NSString *)aOutputTag;

//
// WARNING: refreshFromWeb performs synchronous http request.  Do not run on main thread.
//
-(BOOL)refreshFromWeb:(NSError *__autoreleasing *)aError;

@end
