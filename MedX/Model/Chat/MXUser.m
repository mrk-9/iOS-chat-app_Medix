//
//  MXUser.m
//  MedX
//
//  Created by Ping Ahn on 11/13/15.
//  Copyright © 2015 Hugo. All rights reserved.
//

#import "MXUser.h"
#import "MXMessage.h"
#import "MXRelationship.h"

@implementation MXUser

#pragma mark - Attributes methods

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@", self.preferred_first_name, self.last_name];
}

- (NSString *)fullNameWithSalutation {
    return [NSString stringWithFormat:@"%@ %@ %@", self.salutation, self.preferred_first_name, self.last_name];
}

- (NSString *)shortNameWithSalutation {
    return [NSString stringWithFormat:@"%@ %@", self.salutation, self.last_name];
}

- (NSString *)initials {
    NSMutableString *initials = [NSMutableString string];
    NSString *name = [self fullName];
    if ([name length] > 0) {
        NSArray *words = [name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for (NSString *word in words) {
            if ([word length] > 0) {
                NSString *firstLetter = [word substringToIndex:1];
                [initials appendString:[firstLetter uppercaseString]];
            }
        }
    }
    
    NSRange stringRange = {0, MIN([initials length], (NSUInteger)3)}; // Rendering max 3 letters.
    initials            = [[initials substringWithRange:stringRange] mutableCopy];
    
    return initials;
}

- (NSString *)contactIdentifier {
    return [NSString stringWithFormat:@"%@ %@ %@", self.first_name, self.last_name, self.specialty];
}

- (NSInteger)avtarBGColorIndex {
    return (([self.user_id integerValue] * 29 * [[self contactIdentifier] length]) % 21);
}


#pragma mark - Flag methods

- (BOOL)hasInstalledApp {
    return [AppUtil isNotEmptyString:self.public_key];
}

- (BOOL)isVerified {
    return [self.status integerValue] == MX_USER_STATUS_VERIFIED;
}

@end
