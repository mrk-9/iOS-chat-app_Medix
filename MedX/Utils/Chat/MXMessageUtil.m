//
//  MXMessageUtil.m
//  MedX
//
//  Created by Ping Ahn on 8/29/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXMessageUtil.h"

@implementation MXMessageUtil

#pragma mark - Dump Methods

+ (void)dumpAllMessages {
    // Delets all messages from DB.
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [MXMessage MR_truncateAllInContext:localContext];
        [AppUtil dumpFilesInDirectoryPath:[AppUtil imagesPath]];
    } completion:nil];
}


#pragma mark - CRUD Methods

+ (MXMessage *)createMessageByInfo:(NSDictionary *)info inContext:(NSManagedObjectContext *)context {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"app_message_id LIKE %@", info[@"app_message_id"]];
    MXMessage *message = [MXMessage MR_findFirstWithPredicate:predicate inContext:context];
    
    if ( [AppUtil isEmptyObject:message] )
        message = [MXMessage MR_createEntityInContext:context];
    
    NSDate *sent_at = nil;
    
    for (id key in info) {
        if ( [AppUtil isEmptyObject:info[key]] ) continue;
        
        if ( [info objectForKey:key] ) {

            if ( ![key isEqualToString:@"last_message_date"] ) {
                
                if ( [key isEqualToString:@"sent_at"] ) {
                    if ( [info[key] isKindOfClass:[NSDate class]] ) {
                        [message setValue:info[key] forKey:key];
                        sent_at = info[key];
                    } else {
                        sent_at = [AppUtil getLocalDateFromString:info[key]];
                        [message setValue:sent_at forKey:key];
                    }
                } else {
                    if ( [key isEqualToString:@"type"] || [key isEqualToString:@"status"] ||
                        [key isEqualToString:@"width"] || [key isEqualToString:@"height"] ) {
                        
                        if ( [info[key] isKindOfClass:[NSNumber class]] )
                            [message setValue:info[key] forKey:key];
                        else
                            [message setValue:@([info[key] integerValue]) forKey:key];
                    } else {
                        [message setValue:info[key] forKey:key];
                    }
                }
            }
            
            if ( [key isEqualToString:@"sender_id"] )
                message.sender = [MXUserUtil findByUserId:message.sender_id inContext:context];
                
            else if ( [key isEqualToString:@"recipient_id"] )
                message.recipient = [MXUserUtil findByUserId:message.recipient_id inContext:context];
                
            else if ( [key isEqualToString:@"sent_at"] && sent_at ) {
                
                if ( [info objectForKey:@"sender_id"] && [info objectForKey:@"recipient_id"] ) {
                    
                    MedXUser *currentUser = [MedXUser CurrentUser];
                    NSString *primaryUserId = [currentUser userId];
                    NSString *partner_id = info[@"recipient_id"];
                    if ( [partner_id isEqualToString:primaryUserId] )
                        partner_id = info[@"sender_id"];
                    
                    MXRelationship *rel = [MXRelationshipUtil findRelationshipByUserId:primaryUserId
                                                                             PartnerId:partner_id
                                                                             inContext:context];
                    if ( rel && rel.last_message_date.timeIntervalSince1970 < sent_at.timeIntervalSince1970 ) {
                        rel.last_message_date = sent_at;
                    }
                }
            }
        }
    }

    return message;
}

+ (void)saveMessageByInfo:(NSDictionary *)info attachment:(NSData *)data completion:(void(^)(NSString *app_message_id, NSString *sharedKeyString, NSError *error))completionHandler {
    
    NSMutableDictionary *message_info = [NSMutableDictionary dictionaryWithDictionary:info];
    MedXUser *currentUser = [MedXUser CurrentUser];
    
    NSString *sharedKeyString = nil;
    if ([info[@"type"] integerValue] == MX_MESSAGE_TYPE_PHOTO && data) {
        
        // Encrypts image data
        if ( currentUser.publicKey ) {
            // Generates a shared AES key
            sharedKeyString = [EncryptionUtil generateSharedAESKey];
            
            // Encrypts the shared AES key by current user's public RSA key
            NSString *encryptedSharedKeyString = [EncryptionUtil encryptText:sharedKeyString byPublicKey:currentUser.publicKey];
            
            // Encrypts the attachment data by shared AES key
            data = [EncryptionUtil encryptAttachment:data sharedKeyString:sharedKeyString];
            
            // Stores the encrypted shared AES key into text field
            [message_info setObject:encryptedSharedKeyString forKey:@"text"];
            [message_info setObject:@"1" forKey:@"is_encrypted"];
            
        } else {
            [message_info setObject:@"0" forKey:@"is_encrypted"];
        }
        
        // Save image data to local image directory
        NSString *filepath = [AppUtil imagePathWithFileName:info[@"filename"]];
        BOOL result = [[NSFileManager defaultManager] createFileAtPath:filepath
                                                              contents:data
                                                            attributes:nil];
        if (result) {
            // Prevents the file to be backed up to iCloud and iTunes
            [AppUtil addSkipBackupAttributeToItemAtPath:filepath];
        } else
            NSLog(@"ERROR: failed to store image to local path: %@", filepath);
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    __block MXMessage *message = nil;
    
    // Save in local storage
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        message = [self createMessageByInfo:message_info inContext:localContext];
        
    } completion:^(BOOL success, NSError *error) {
        
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        
        if (completionHandler)
            completionHandler(info[@"app_message_id"], sharedKeyString, error);
    }];
}

+ (void)saveIncomingMessages:(NSArray *)incomingMessages
                       reads:(NSArray *)readAppMessageIds
                  completion:(void(^)(BOOL success, NSError *error))completionHandler {
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Save in local storage
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        for (NSDictionary *message_info in incomingMessages) {
            NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:message_info];
            [info setObject:@(MX_MESSAGE_STATUS_SENT) forKey:@"status"];
            MXMessage *message = [self createMessageByInfo:info inContext:localContext];
            
            NSLog(@"sender first name: %@", message.sender.first_name);
            NSLog(@"recipient first name: %@", message.recipient.first_name);
        }
        
        for (NSString *app_message_id in readAppMessageIds) {
            NSDictionary *info = @{@"app_message_id": app_message_id,
                                   @"status"        : @(MX_MESSAGE_STATUS_READ)};
            [self createMessageByInfo:info inContext:localContext];
        }
        
    } completion:^(BOOL success, NSError *error) {
        
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        
        if (completionHandler)
            completionHandler(success, error);
    }];
}

// Marks array of app_message_ids to a status
+ (void)updateMessagesInAppMessageIds:(NSArray *)appMessageIds withNewStatus:(int)status IsOnlyForTextMessage:(BOOL)isOnlyTextMessage completion:(void(^)(BOOL success, NSError *error))completionHandler {
    
    if ( [appMessageIds count] == 0 ) {
        if ( completionHandler )
            completionHandler(YES, nil);
        return;
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Save in local storage
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"app_message_id IN %@", appMessageIds];
        
        NSArray *messages = [MXMessage MR_findAllWithPredicate:predicate inContext:localContext];
        for (MXMessage *m in messages) {
            if (isOnlyTextMessage) {
                if ([m.type integerValue] == MX_MESSAGE_TYPE_TEXT)
                    m.status = @(status);
            } else
                m.status = @(status);
        }
        
    } completion:^(BOOL success, NSError *error) {
        
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        
        if (completionHandler)
            completionHandler(success, error);
    }];
}


#pragma mark - Find Methods

+ (MXMessage *)findLastMessageBetweenUser1:(NSString *)user_id1 andUser2:(NSString *)user_id2 {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sender_id LIKE %@ AND recipient_id LIKE %@) OR "
                                                               "(sender_id LIKE %@ AND recipient_id LIKE %@)",
                                                               user_id1, user_id2,
                                                               user_id2, user_id1];
    
    return [MXMessage MR_findFirstWithPredicate:predicate sortedBy:@"sent_at" ascending:NO];
}

+ (NSArray *)findMessagesBetweenUser1:(NSString *)user_id1 andUser2:(NSString *)user_id2 {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sender_id LIKE %@ AND recipient_id LIKE %@) OR "
                                                              "(sender_id LIKE %@ AND recipient_id LIKE %@)",
                                                              user_id1, user_id2,
                                                              user_id2, user_id1];
    
    return [MXMessage MR_findAllSortedBy:@"sent_at" ascending:YES withPredicate:predicate];
}

+ (NSArray *)findMessagesBetweenUser1:(NSString *)user_id1 andUser2:(NSString *)user_id2 LastSentAt:(NSDate *)lastSentAt PageSize:(int)pageSize {

    NSPredicate *predicate = nil;
    if (!lastSentAt) {
        predicate = [NSPredicate predicateWithFormat:@"(sender_id LIKE %@ AND recipient_id LIKE %@) OR "
                                  "(sender_id LIKE %@ AND recipient_id LIKE %@)",
                                  user_id1, user_id2,
                                  user_id2, user_id1];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"((sender_id LIKE %@ AND recipient_id LIKE %@) OR "
                                  "(sender_id LIKE %@ AND recipient_id LIKE %@)) AND "
                                  "sent_at < %@",
                                  user_id1, user_id2,
                                  user_id2, user_id1,
                                  lastSentAt];
    }
    NSFetchRequest *fetchRequest = [MXMessage MR_requestAllSortedBy:@"sent_at" ascending:NO withPredicate:predicate];
    fetchRequest.fetchLimit = pageSize;
    
    return [MXMessage MR_executeFetchRequest:fetchRequest];
}

+ (NSArray *)findMessagesBetweenUser1:(NSString *)user_id1 andUser2:(NSString *)user_id2 LatestSentAt:(NSDate *)latestSentAt {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((sender_id LIKE %@ AND recipient_id LIKE %@) OR "
                                                               "(sender_id LIKE %@ AND recipient_id LIKE %@)) AND "
                                                               "sent_at > %@",
                                                               user_id1, user_id2,
                                                               user_id2, user_id1,
                                                               latestSentAt];
    return [MXMessage MR_findAllSortedBy:@"sent_at" ascending:YES withPredicate:predicate];
}


#pragma mark - Attribute Methods

+ (NSString *)appMessageIdByUserId:(NSString *)user_id datetime:(NSDate *)date {
    
    return [NSString stringWithFormat:@"%@.%@", user_id, [AppUtil timestampByDate:date]];
}

+ (NSString *)imageFileNameByAppMessageId:(NSString *)app_message_id {
    
    return [NSString stringWithFormat:@"%@.jpg", app_message_id];
}

+ (NSString *)temporaryDownloadPathByAppMessageId:(NSString *)app_message_id {
    NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *tempPath = [pathList  objectAtIndex:0];
    
    return [tempPath stringByAppendingFormat:@"/%@/", app_message_id];
}

+ (NSString *)temporaryPathByFileName:(NSString *)fileName {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

+ (BOOL)checkLocalImageExistsForMessage:(NSDictionary *)message_info {
    
    NSString *filepath = [AppUtil imagePathWithFileName:message_info[@"filename"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ( [fileManager fileExistsAtPath:filepath] ) {
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filepath error:nil];
        if ( fileAttributes ) {
            NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
            if ( fileSize && [fileSize integerValue] > 0 ) {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (UIImage *)imageOfMessage:(NSDictionary *)message_info {
    
    NSString *filepath = [AppUtil imagePathWithFileName:message_info[@"filename"]];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filepath];
    
    if (fileExists) {
        NSData *data = [NSData dataWithContentsOfFile:filepath];
        
        // Decrypts data
        if ( [message_info[@"is_encrypted"] isEqualToString:@"1"] ) {
            NSData *decryptedAttachment = [EncryptionUtil decryptLocalAttachment:data
                                                                 sharedKeyString:message_info[@"text"]];
            return [UIImage imageWithData:decryptedAttachment];
        }
        
        return [UIImage imageWithData:data];
    }
    return nil;
}

+ (NSData *)attachmentByImage:(UIImage *)image {
    
    return UIImageJPEGRepresentation(image, 0.7f);
}

+ (NSMutableDictionary *)dictionaryWithValuesFromMessage:(MXMessage *)message {
    NSArray *keys = [[[message entity] attributesByName] allKeys];
    
    NSMutableDictionary *message_info = [NSMutableDictionary dictionaryWithDictionary:[message dictionaryWithValuesForKeys:keys]];
    
    if ( [message.type integerValue] == MX_MESSAGE_TYPE_TEXT ) {
        if ( [message.is_encrypted isEqualToString:@"1"] )
            message_info[@"text"] = [EncryptionUtil decryptLocalText:message.text];
        
    } else {
        // For Photo type message
        if ( [AppUtil isNotEmptyString:message.text] ) {
            MedXUser *currentUser = [MedXUser CurrentUser];
            // Decrypts the encrypted shared AES key by current user's private RSA key
            NSString *decryptedSharedKeyString = [EncryptionUtil decryptText:message.text byPrivateKey:currentUser.privateKey];
            message_info[@"text"] = decryptedSharedKeyString;
        }
    }
    return message_info;
}


#pragma mark - Count Methods

+ (int)countOfUnreadMessageRecipient:(MXUser *)recipient bySender:(MXUser *)sender {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recipient_id LIKE %@ AND sender_id LIKE %@ AND status != %d",
                              recipient.user_id, sender.user_id, MX_MESSAGE_STATUS_READ];
    return (int)[MXMessage MR_countOfEntitiesWithPredicate:predicate];
}

+ (int)countOfUnreadMessageRecipient:(MXUser *)recipient {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recipient_id LIKE %@ AND status != %d",
                              recipient.user_id, MX_MESSAGE_STATUS_READ];
    return (int)[MXMessage MR_countOfEntitiesWithPredicate:predicate];
}


#pragma mark - Delete Methods

+ (void)deleteOldMessagesForUserId:(NSString *)user_id completion:(void(^)(BOOL success, NSError *error))completionHandler {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *deletingMessageIds = [NSMutableArray array];
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    
    // Collects old messages info
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sender_id LIKE %@ OR recipient_id LIKE %@)", user_id, user_id];
    NSArray *messages = [MXMessage MR_findAllWithPredicate:predicate];
    for (MXMessage *msg in messages) {
        NSTimeInterval sentAtInterval = [msg.sent_at timeIntervalSince1970];
        if ( timeStamp - sentAtInterval >= MX_TIME_INTERVAL_DIFF_WEEK ) {
            [deletingMessageIds addObject:msg.app_message_id];
            
            if ( [msg.type integerValue] == MX_MESSAGE_TYPE_PHOTO ) {
                NSString *filepath = [AppUtil imagePathWithFileName:msg.filename];
                NSError *error = nil;
                [fileManager removeItemAtPath:filepath error:&error];
            }
        }
    }
    
    // Deletes old messages in local store
    if ( [deletingMessageIds count] > 0 ) {
        UIApplication *application = [UIApplication sharedApplication];
        __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"app_message_id IN %@", deletingMessageIds];
            [MXMessage MR_deleteAllMatchingPredicate:predicate inContext:localContext];
        
        } completion:^(BOOL success, NSError *error) {
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
            
            if ( completionHandler ) completionHandler(success, error);
        }];
    } else {
        if ( completionHandler ) completionHandler(YES, nil);
    }
}

+ (void)deleteConversationBetweenUser1:(NSString *)user_id1 User2:(NSString *)user_id2 completion:(void(^)(BOOL success, NSError *error))completionHandler {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *deletingMessageIds = [NSMutableArray array];
    
    // Collects messages between user1 and user2
    // Deletes message photos in local file system
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sender_id LIKE %@ AND recipient_id LIKE %@) OR "
                              "(sender_id LIKE %@ AND recipient_id LIKE %@)", user_id1, user_id2, user_id2, user_id1];
    NSArray *messages = [MXMessage MR_findAllSortedBy:@"sent_at" ascending:YES withPredicate:predicate];
    for (MXMessage *msg in messages) {
            [deletingMessageIds addObject:msg.app_message_id];
            
            if ( [msg.type integerValue] == MX_MESSAGE_TYPE_PHOTO ) {
                NSString *filepath = [AppUtil imagePathWithFileName:msg.filename];
                NSError *error = nil;
                [fileManager removeItemAtPath:filepath error:&error];
            }

    }
    
    // Deletes messages in local store
    if ( [deletingMessageIds count] > 0 ) {
        UIApplication *application = [UIApplication sharedApplication];
        __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"app_message_id IN %@", deletingMessageIds];
            [MXMessage MR_deleteAllMatchingPredicate:predicate inContext:localContext];
            
        } completion:^(BOOL success, NSError *error) {
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
            
            if ( completionHandler ) completionHandler(success, error);
        }];
    } else {
        if ( completionHandler ) completionHandler(YES, nil);
    }
}

@end
