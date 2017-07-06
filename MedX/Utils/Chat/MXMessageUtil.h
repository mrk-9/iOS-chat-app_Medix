//
//  MXMessageUtil.h
//  MedX
//
//  Created by Ping Ahn on 8/29/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MXMessageUtil : NSObject

#pragma mark - Dump Methods

+ (void)dumpAllMessages;


#pragma mark - CRUD Methods

+ (void)saveMessageByInfo:(NSDictionary *)info
               attachment:(NSData *)data
               completion:(void(^)(NSString *app_message_id, NSString *sharedKeyString, NSError *error))completionHandler;

+ (void)saveIncomingMessages:(NSArray *)incomingMessages
                       reads:(NSArray *)readAppMessageIds
                  completion:(void(^)(BOOL success, NSError *error))completionHandler;

+ (void)updateMessagesInAppMessageIds:(NSArray *)appMessageIds
                        withNewStatus:(int)status
                 IsOnlyForTextMessage:(BOOL)isOnlyTextMessage
                           completion:(void(^)(BOOL success, NSError *error))completionHandler;

#pragma mark - Find Methods

+ (MXMessage *)findLastMessageBetweenUser1:(NSString *)user_id1
                                  andUser2:(NSString *)user_id2;
+ (NSArray *)findMessagesBetweenUser1:(NSString *)user_id1
                             andUser2:(NSString *)user_id2;
+ (NSArray *)findMessagesBetweenUser1:(NSString *)user_id1
                             andUser2:(NSString *)user_id2
                           LastSentAt:(NSDate *)lastSentAt
                             PageSize:(int)pageSize;
+ (NSArray *)findMessagesBetweenUser1:(NSString *)user_id1
                             andUser2:(NSString *)user_id2
                         LatestSentAt:(NSDate *)latestSentAt;


#pragma mark - Attribute Methods

+ (NSString *)appMessageIdByUserId:(NSString *)user_id datetime:(NSDate *)date;
+ (NSString *)imageFileNameByAppMessageId:(NSString *)app_message_id;
+ (NSString *)temporaryDownloadPathByAppMessageId:(NSString *)app_message_id;
+ (NSString *)temporaryPathByFileName:(NSString *)fileName;
+ (BOOL)checkLocalImageExistsForMessage:(NSDictionary *)message_info;
+ (UIImage *)imageOfMessage:(NSDictionary *)message_info;
+ (NSData *)attachmentByImage:(UIImage *)image;
+ (NSMutableDictionary *)dictionaryWithValuesFromMessage:(MXMessage *)message;


#pragma mark - Count Methods

+ (int)countOfUnreadMessageRecipient:(MXUser *)recipient
                                bySender:(MXUser *)sender;
+ (int)countOfUnreadMessageRecipient:(MXUser *)recipient;


#pragma mark - Delete Methods

+ (void)deleteOldMessagesForUserId:(NSString *)user_id
                        completion:(void(^)(BOOL success, NSError *error))completionHandler;
+ (void)deleteConversationBetweenUser1:(NSString *)user_id1
                                 User2:(NSString *)user_id2
                            completion:(void(^)(BOOL success, NSError *error))completionHandler;

@end
