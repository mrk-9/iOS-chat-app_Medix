//
//  MXUserUtil.m
//  MedX
//
//  Created by Ping Ahn on 8/26/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXUserUtil.h"

@implementation MXUserUtil

#pragma mark - CRUD Methods

+ (MXUser *)createUser:(NSDictionary *)info inContext:(NSManagedObjectContext *)context {
    
    MXUser *user = [MXUser MR_findFirstByAttribute:@"user_id" withValue:info[@"user_id"] inContext:context];
    if ([AppUtil isEmptyObject:user]) {
        user = [MXUser MR_createEntityInContext:context];
    }
    
    NSArray *field_names = @[@"user_id", @"first_name", @"last_name", @"specialty", @"salutation", @"status",
                             @"preferred_first_name", @"address", @"locations", @"about", @"public_key",];

    for (id key in info) {
        if ( [field_names indexOfObject:key] == NSNotFound) continue;
        
        if ( [key isEqualToString:@"status"] ) {
            [user setValue:info[key] forKey:key];
            
        } else {
            NSString *oldValue = [user valueForKey:key];
            NSString *newValue = [info valueForKey:key];
            
            if ( ![oldValue isEqualToString:newValue] ) {
                if ( [AppUtil isEmptyObject:newValue] )
                    [user setValue:@"" forKey:key];
                else
                    [user setValue:newValue forKey:key];
            }
        }
    }

    return user;
}

+ (void)saveUserByInfo:(NSDictionary *)info completion:(void(^)(NSString *user_id, NSError *error))completionHandler {
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Save in local storage
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        [self createUser:info inContext:localContext];
        
    } completion:^(BOOL success, NSError *error) {
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        
        if ( completionHandler )
            completionHandler(info[@"user_id"], error);
    }];
}

+ (void)saveUsers:(NSArray *)users_info forPrimaryUser:(NSString *)primaryUserId completion:(void(^)(BOOL success,  NSError *error))onSaveCompletion {
    if ([users_info count] == 0) {
        if ( onSaveCompletion )
            onSaveCompletion(YES, nil);
        return;
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Save in local storage
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        for (NSDictionary *info in users_info) {
            BOOL hasToCreateRelation = NO;
            if ( ![MXUser MR_findFirstByAttribute:@"user_id" withValue:info[@"user_id"]] ) {
                hasToCreateRelation = YES;
            }
            
            [self createUser:info inContext:localContext];
            
            if ( hasToCreateRelation && primaryUserId ) {
                [MXRelationshipUtil createRelationshipByInfo:info forUserId:primaryUserId inContext:localContext];
            }
        }
        
    } completion:^(BOOL success, NSError *error) {
        
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        
        if (onSaveCompletion)
            onSaveCompletion(success, error);
    }];
}


#pragma mark - Find Methods

+ (MXUser *)findByUserId:(NSString *)user_id inContext:(NSManagedObjectContext *)context {
    
    if (context)
        return [MXUser MR_findFirstByAttribute:@"user_id" withValue:user_id inContext:context];
    
    return [MXUser MR_findFirstByAttribute:@"user_id" withValue:user_id];
}


#pragma mark - NSUserDefaults Methods

+ (BOOL)checkUserInfoExistsFromUserDefaults:(NSUserDefaults *)defaults {
    return [AppUtil checkUserDefaults:defaults hasKey:@"MedXUser"];
}

+ (void)updateUserDefaults:(NSUserDefaults *)defaults withUserInfo:(NSDictionary *)userInfo LastLogin:(NSDate *)date {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    if ( userInfo ) [params setObject:userInfo forKey:@"MedXUser"];
    if ( date ) [params setObject:date forKey:@"timestamp"];
    
    [AppUtil setUserDefaults:defaults withParams:params];
}

+ (NSDictionary *)getUserInfoFromUserDefaults:(NSUserDefaults *)defaults {
    return [AppUtil getValueFromUserDefaults:defaults forKey:@"MedXUser"];
}

+ (void)updateUserDefaults:(NSUserDefaults *)defaults withLastLoginDate:(NSDate *)date  {
    NSDate *lastLogin = date == nil ? [NSDate date] : date;
    [AppUtil setUserDefaults:defaults withValue:lastLogin forKey:@"timestamp"];
}

+ (NSDate *)getLastLoginFromUserDefaults:(NSUserDefaults *)defaults {
    return [AppUtil getValueFromUserDefaults:defaults forKey:@"timestamp"];
}

+ (void)updateUserDefaults:(NSUserDefaults *)defaults withDeviceToken:(NSString *)deviceToken {
    [AppUtil setUserDefaults:defaults withValue:deviceToken forKey:@"deviceToken"];
}

+ (NSString *)getDeviceTokenFromUserDefaults:(NSUserDefaults *)defaults {
    return [AppUtil getValueFromUserDefaults:defaults forKey:@"deviceToken"];
}

+ (BOOL)checkEncryptionKeysExistsFromUserDefaults:(NSUserDefaults *)defaults {
    return [AppUtil checkUserDefaults:defaults hasKey:@"MedXKeys"];
}

+ (void)updateUserDefaults:(NSUserDefaults *)defaults withEncryptionKeys:(NSArray *)keys {
    // keys[0]: RSA Public Key String, keys[1]: RSA Private Key Data
    [AppUtil setUserDefaults:defaults withValue:keys forKey:@"MedXKeys"];
}

+ (NSArray *)getEncryptionKeysFromUserDefaults:(NSUserDefaults *)defaults {
    return [AppUtil getValueFromUserDefaults:defaults forKey:@"MedXKeys"];
}

+ (void)removeEncryptionKeysFromUserDefaults:(NSUserDefaults *)defaults {
    [AppUtil removeObjectsFromUserDefaults:defaults forKeys:@[@"MedXKeys"]];
}

+ (void)updateUserDefaults:(NSUserDefaults *)defaults withLoginExpirePeriod:(NSString *)expirePeriod {
    [AppUtil setUserDefaults:defaults withValue:expirePeriod forKey:@"login_expire_period"];
}

+ (NSString *)getLoginExpirePeriodFromUserDefaults:(NSUserDefaults *)defaults {
    NSString *period = [AppUtil getValueFromUserDefaults:defaults forKey:@"login_expire_period"];
    if ( [AppUtil isEmptyString:period] )
        period = @"1 Day";
    
    return period;
}

+ (NSUInteger)getLoginExpirePeriodInSeconds {
    NSString *period   = [self getLoginExpirePeriodFromUserDefaults:nil];
    NSUInteger seconds = 0;
    
    if ( [period isEqualToString:@"1 Hour"] )
        seconds = 60 * 60;
    else if ( [period isEqualToString:@"1 Day"] )
        seconds = 24 * 60 * 60;
    else if ( [period isEqualToString:@"3 Days"] )
        seconds = 3 * 24 * 60 * 60;
    else if ( [period isEqualToString:@"1 Week"] )
        seconds = 7 * 24 * 60 * 60;
    else if ( [period isEqualToString:@"1 Minute"] )
        seconds = 60;

    return seconds;
}

+ (void)removeUserParamsFromUserDefaults:(NSUserDefaults *)defautls {
    [AppUtil removeObjectsFromUserDefaults:defautls forKeys:@[@"MedXUser", @"timestamp", @"deviceToken", @"login_expire_period"]];
}


#pragma mark - Utility methods

+ (NSString *)refineOfficePhoneNumberInLocation:(NSString *)location {
    NSMutableArray *addresses = [NSMutableArray arrayWithArray: [location componentsSeparatedByString:@"\n"]];
    NSString       *phone     = [addresses lastObject];
    
    [addresses removeLastObject];
    [addresses addObject:[AppUtil formatOfficePhoneNumber:phone]];
    
    return [addresses componentsJoinedByString:@"\n"];
}

@end
