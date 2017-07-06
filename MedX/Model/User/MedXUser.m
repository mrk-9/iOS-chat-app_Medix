//
//  MedXUser.m
//  MedX
//
//  Created by Anthony Zahra on 6/12/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MedXUser.h"

static MedXUser *user;

@implementation MedXUser

#pragma mark - Init Methods

+ (MedXUser *)CurrentUser {
    
    if (user == nil) {
        user = [[MedXUser alloc] init];
        user.userDialogs = [[NSMutableDictionary alloc] init];
    }
    
    return user;
}

- (id)init {
    if (self = [super init]) {
        self.info = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setUserInfo:(NSDictionary *)info {
    
    self.info = [NSMutableDictionary dictionary];
    
    if ( [info objectForKey:@"access_token"] )
        [self.info setObject:info[@"access_token"] forKey:@"access_token"];
    
    if ( [info objectForKey:@"offices"] )
        [self.info setObject:info[@"offices"] forKey:@"offices"];
    
    if ( [AppUtil isNotEmptyObject:[info objectForKey:@"salutation"]] )
        [self.info setObject:info[@"salutation"] forKey:@"salutation"];
    
    if ( [AppUtil isNotEmptyObject:[info objectForKey:@"preferred_first_name"]] )
        [self.info setObject:info[@"preferred_first_name"] forKey:@"preferred_first_name"];
    
    if ( [AppUtil isNotEmptyObject:[info objectForKey:@"about"]] )
        [self.info setObject:info[@"about"] forKey:@"about"];
    
    [self.info setObject:info[@"user_id"] forKey:@"user_id"];
    
    if ( [info objectForKey:@"blocked_user_ids"] ) {
        [self.info setObject:info[@"blocked_user_ids"] forKey:@"blocked_user_ids"];
    }
    
    [self setupKeys];
}

- (void)setupKeys {
    NSArray *keyPair = [MXUserUtil getEncryptionKeysFromUserDefaults:nil];
    
    if ( keyPair ) {
        NSString *publicKeyString = keyPair[0];
        NSData *privateKeyDataValue = keyPair[1];
        
        self.publicKey = [[MIHRSAPublicKey alloc] initWithData:[NSData dataFromBase64String:publicKeyString]];
        self.privateKey = [[MIHRSAPrivateKey alloc] initWithData:privateKeyDataValue];
    }
}

- (void)unset {
    self.info = nil;
    self.publicKey = nil;
    self.privateKey = nil;
}


#pragma mark - Attributes Methods

- (MXUser *)dbUser {
    
    return [MXUser MR_findFirstByAttribute:@"user_id" withValue:self.info[@"user_id"]];
}

- (NSString *)accessToken {
    return self.info[@"access_token"];
}

- (NSString *)userId {
    return self.info[@"user_id"];
}

- (NSMutableArray *)blockedUserIds {
    NSMutableArray *blocked_ids = [NSMutableArray array];
    if ( [self.info objectForKey:@"blocked_user_ids"] ) {
        [blocked_ids addObjectsFromArray:self.info[@"blocked_user_ids"]];
    }
    return blocked_ids;
}

- (void)addBlockedUserId:(NSString *)user_id {
    NSMutableArray *blocked_ids = [self blockedUserIds];
    
    [blocked_ids addObject:user_id];
    self.info[@"blocked_user_ids"] = blocked_ids;
    [MXUserUtil updateUserDefaults:nil withUserInfo:self.info LastLogin:[NSDate date]];
}

- (void)removeBlockedUserId:(NSString *)user_id {
    NSMutableArray *blocked_ids = [self blockedUserIds];
    if ([blocked_ids containsObject:user_id] ) {
        [blocked_ids removeObject:user_id];
    }
    self.info[@"blocked_user_ids"] = blocked_ids;
    [MXUserUtil updateUserDefaults:nil withUserInfo:self.info LastLogin:[NSDate date]];
}

- (void)updateUserDialogsWithReadSentMessages:(NSArray *)readAppMessageIds {
    for (NSString *user_id in _userDialogs) {
        NSMutableArray *userMessages = _userDialogs[user_id];
        for (NSMutableDictionary *message_info in userMessages) {
            if ( [readAppMessageIds indexOfObject:message_info[@"app_message_id"]] != NSNotFound )
                message_info[@"status"] = @(MX_MESSAGE_STATUS_READ);
        }
    }
}


#pragma mark - Check Methods

- (BOOL)checkUserLoggedIn {
    return [self.info count] > 0;
}

- (BOOL)isBlockingUserId:(NSString *)user_id {
    NSMutableArray *blocked_ids = [self blockedUserIds];
    return [blocked_ids containsObject:user_id];
}


#pragma mark - Badge Methods

- (void)resetApplicationBadge {
    int totalUnreadMessages = [MXMessageUtil countOfUnreadMessageRecipient:[self dbUser]];
    [AppUtil setAppIconBadgeNumber:totalUnreadMessages];
}


#pragma mark - API methods

- (void)blockOrUnblockUserById:(NSString *)user_id isBlock:(BOOL)isBlock completion:(void(^)(BOOL success, NSString *errorStatus))completionHandler {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[self accessToken] forKey:@"token"];
    [params setObject:user_id forKey:@"user_id"];
    
    NSString *route = isBlock ? @"users/block" : @"users/unblock";

    [[BackendBase sharedConnection] accessAPIbyPOST:route Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"MedXUser > blockOrUnblockUserById result: %@", result);
        if ( !error ) {
            NSString *response = result[@"response"];
            if ( [response isEqualToString:@"fail"] ) {
                [MXUserUtil updateUserDefaults:nil withLastLoginDate:nil];
                if (completionHandler) completionHandler(NO, nil);
                
            } else {
                if (isBlock)
                    [self addBlockedUserId:user_id];
                else
                    [self removeBlockedUserId:user_id];
                
                if (completionHandler) completionHandler(YES, nil);
            }
            
        } else {
            NSLog(@"MedXUser > blockOrUnblockUserById Network ERROR - %@", error.description);
            
            if (completionHandler) completionHandler(NO, nil);
        }
    }];
}

- (void)registerDeviceToken:(NSString *)deviceToken completion:(void(^)(BOOL success))completionHandler {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:[self accessToken] forKey:@"token"];
    [params setObject:deviceToken forKey:@"device_token"];
    [params setObject:@"ios" forKey:@"device_type"];
    
    [[BackendBase sharedConnection] accessAPIbyPOST:@"users/device" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"MedXUser > registerDeviceToken result: %@", result);
        
        if ( !error ) {
            NSString *response = result[@"response"];
            if ( [response isEqualToString:@"fail"] ) {
                NSLog(@"Failed to register device token to server. Status: %@", result[@"status"]);
                if (completionHandler) completionHandler(NO);
            } else {
                NSLog(@"Successfully registered device token to server.");
                if (completionHandler) completionHandler(YES);
            }
            [MXUserUtil updateUserDefaults:nil withLastLoginDate:nil];
            
        } else {
            NSLog(@"MedXUser > registerDeviceToken Network ERROR - %@", error.description);
            if (completionHandler) completionHandler(NO);
        }
    }];
}

- (void)registerPublicKey:(NSString *)publicKeyString completion:(void(^)(BOOL success, NSError *error))completionHandler {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:[self accessToken] forKey:@"token"];
    [params setObject:publicKeyString forKey:@"public_key"];
    
    [[BackendBase sharedConnection] accessAPIbyPOST:@"users/public_key" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"MedXUser > registerPublicKey result: %@", result);
        
        if ( !error ) {
            NSString *response = result[@"response"];
            if ( [response isEqualToString:@"fail"] ) {
                NSLog(@"Failed to register public key to server. Status: %@", result[@"status"]);
                if (completionHandler) completionHandler(NO, nil);
            } else {
                NSLog(@"Successfully registered public key to server.");
                if (completionHandler) completionHandler(YES, nil);
            }
            
        } else {
            NSLog(@"MedXUser > registerPublicKey Network ERROR - %@", error.description);
            if (completionHandler) completionHandler(NO, error);
        }
    }];
}

- (void)inviteUser:(NSString *)user_id PhoneNumber:(NSString *)phone completion:(void(^)(BOOL success, NSString *errorMessage))completionHandler {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:[self accessToken] forKey:@"token"];
    [params setObject:user_id forKey:@"invitee"];
    [params setObject:phone forKey:@"phone"];
    
    [[BackendBase sharedConnection] accessAPIbyPOST:@"users/invite" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"MedXUser > inviteUser result: %@", result);
        
        if ( !error ) {
            NSString *response = result[@"response"];
            if ( [response isEqualToString:@"fail"] ) {
                NSString *status = result[@"status"];
                NSString *errorMessage = @"Could not invite the doctor. Please try again later!";
                if ( [status isEqualToString:@"verified"] )
                    errorMessage = @"The doctor has already been verified. Please pull to refresh the search!";
                else if ( [status isEqualToString:@"phone"] )
                    errorMessage = @"The phone has already been used by another doctor!";
                
                if (completionHandler) completionHandler(NO, errorMessage);
                
            } else {
                if (completionHandler) completionHandler(YES, nil);
            }
            
        } else {
            NSLog(@"MedXUser > inviteUser Network ERROR - %@", error.description);
            if (completionHandler) completionHandler(NO, MX_ALERT_NETWORK_ERROR);
        }
    }];
}

@end
