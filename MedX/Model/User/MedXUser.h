//
//  MedXUser.h
//  MedX
//
//  Created by Anthony Zahra on 6/12/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXUser.h"
#import "MIHRSAPublicKey.h"
#import "MIHRSAPrivateKey.h"

@interface MedXUser : NSObject

#pragma mark - Properties

@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) NSMutableDictionary *info;
@property (nonatomic, strong) NSMutableDictionary *userDialogs;

@property (nonatomic, strong) MIHRSAPublicKey *publicKey;
@property (nonatomic, strong) MIHRSAPrivateKey *privateKey;


#pragma mark - Init Methods

+ (MedXUser *)CurrentUser;
- (void)setUserInfo:(NSDictionary *)info;
- (void)setupKeys;
- (void)unset;


#pragma mark - Attributes Methods

- (MXUser *)dbUser;
- (NSString *)accessToken;
- (NSString *)userId;
- (void)updateUserDialogsWithReadSentMessages:(NSArray *)readAppMessageIds;


#pragma mark - Check Methods

- (BOOL)checkUserLoggedIn;
- (BOOL)isBlockingUserId:(NSString *)user_id;


#pragma mark - Badge Methods

- (void)resetApplicationBadge;


#pragma mark - API methods

- (void)blockOrUnblockUserById:(NSString *)user_id
                       isBlock:(BOOL)isBlock
                    completion:(void(^)(BOOL success, NSString *errorStatus))completionHandler;

- (void)registerDeviceToken:(NSString *)deviceToken
                 completion:(void(^)(BOOL success))completionHandler;

- (void)registerPublicKey:(NSString *)publicKeyString
               completion:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)inviteUser:(NSString *)user_id
       PhoneNumber:(NSString *)phone
        completion:(void(^)(BOOL success, NSString *errorMessage))completionHandler;

@end
