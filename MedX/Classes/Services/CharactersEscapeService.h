//
//  CharactersEscapeService.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CharactersEscapeService : NSObject

+ (NSString *)escape:(NSString *)unescapedString;
+ (NSString *)unescape:(NSString *)escapedString;

@end
