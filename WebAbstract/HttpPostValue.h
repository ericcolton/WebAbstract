//
//  PostVariable.h
//  WebAbstractDemo
//
//  Created by Eric Colton on 6/4/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HttpPostValue : NSObject

typedef enum { HttpPostValueLiteral, HttpPostValueVariable } HttpPostValueType;

@property (assign, nonatomic) HttpPostValueType type;
@property (strong, nonatomic) NSString *value;

@end
