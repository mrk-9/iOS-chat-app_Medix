//
//  MXUserUtil.h
//  MedX
//
//  Created by Ping Ahn on 8/26/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MXUserUtil : NSObject

#pragma mark - CRUD Methods

+ (MXUser *)createUser:(NSDictionary *)info
             inContext:(NSManagedObjectContext *)context;

+ (void)saveUserByInfo:(NSDictionary *)info
            completion:(void(^)(NSString *user_id, NSError *error))completionHandler;

+ (void)saveUsers:(NSArray *)users_info
   forPrimaryUser:(NSString *)primaryUserId
       completion:(void(^)(BOOL success,  NSError *error))onSaveCompletion;


#pragma mark - Find Methods

+ (MXUser *)findByUserId:(NSString *)user_id inContext:(NSManagedObjectContext *)context;

#pragma mark - NSUserDefaults Methods

+ (BOOL)checkUserInfoExistsFromUserDefaults:(NSUserDefaults *)defaults;

+ (void)updateUserDefaults:(NSUserDefaults *)defaults
              withUserInfo:(NSDictionary *)userInfo
                 LastLogin:(NSDate *)date;
+ (NSDictionary *)getUserInfoFromUserDefaults:(NSUserDefaults *)defaults;

+ (void)updateUserDefaults:(NSUserDefaults *)defaults
         withLastLoginDate:(NSDate *)date;
+ (NSDate *)getLastLoginFromUserDefaults:(NSUserDefaults *)defaults;

+ (void)updateUserDefaults:(NSUserDefaults *)defaults
           withDeviceToken:(NSString *)deviceToken;
+ (NSString *)getDeviceTokenFromUserDefaults:(NSUserDefaults *)defaults;

+ (void)updateUserDefaults:(NSUserDefaults *)defaults
        withEncryptionKeys:(NSArray *)keys;
+ (NSArray *)getEncryptionKeysFromUserDefaults:(NSUserDefaults *)defaults;
+ (void)removeEncryptionKeysFromUserDefaults:(NSUserDefaults *)defaults;

+ (void)updateUserDefaults:(NSUserDefaults *)defaults
     withLoginExpirePeriod:(NSString *)expirePeriod;
+ (NSString *)getLoginExpirePeriodFromUserDefaults:(NSUserDefaults *)defaults;
+ (NSUInteger)getLoginExpirePeriodInSeconds;

+ (void)removeUserParamsFromUserDefaults:(NSUserDefaults *)defautls;

#pragma mark - Utility methods

/**
 * Refine a location string by formatting office phone # to display.
 * @param location string: 102 St.\\nRichmond VIC 3000\\n0233335555
 *
 * @return refined location string : 102 St.\\nRichmond VIC 3000\\n(02) 3333 5555
 */
+ (NSString *)refineOfficePhoneNumberInLocation:(NSString *)location;

@end
