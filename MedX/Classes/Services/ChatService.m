//
//  ChatService.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "ChatService.h"
#import "AppDelegate.h"

@interface ChatService () {
    
    int callback_count;
    BOOL isCheckDialogInProgress;
    NSTimer *timer;
}

@end


@implementation ChatService

#pragma mark - Init Methods

+ (instancetype)instance {
    static id instance_ = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance_ = [[self alloc] init];
	});

	return instance_;
}

- (id)init{
    self = [super init];
    if ( self ) {
    }
    return self;
}

- (void)logout {
}


#pragma mark - Sending Messages

- (void)sendTextMessage:(id)message localStoreCompletion:(void(^)(NSString *app_message_id, NSError *error))localStoreCompletionHandler deliverCompletion:(void(^)(NSString *app_message_id, int message_status))deliverCompletionHandler {
    NSMutableDictionary *message_info = [NSMutableDictionary dictionaryWithDictionary:message];
    
    MedXUser *currentUser = [MedXUser CurrentUser];
    
    // Encrypts the text by current user's public RSA key for local storage
    if ( currentUser.publicKey ) {
        message_info[@"text"] = [EncryptionUtil encryptText:message[@"text"] byPublicKey:currentUser.publicKey];
        [message_info setObject:@"1" forKey:@"is_encrypted"];
    } else {
        [message_info setObject:@"0" forKey:@"is_encrypted"];
    }

    // Saves chat history to Local
    [MXMessageUtil saveMessageByInfo:message_info attachment:nil completion:^(NSString *app_message_id, NSString *sharedKeyString, NSError *error) {
        if ( app_message_id ) {
            
            NSLog(@"Message with app_message_id:%@ stored in local successfully.", app_message_id);
            if (localStoreCompletionHandler)
                localStoreCompletionHandler(app_message_id, error);
            
            MXMessage *savedMessage = [MXMessage MR_findFirstByAttribute:@"app_message_id" withValue:app_message_id];
            
            // Encrypts the sending text by recipient's public RSA key
            NSString *is_encrypted = @"0";
            NSString *sendingText = message[@"text"];
            
            if ( savedMessage.recipient && [AppUtil isNotEmptyString:savedMessage.recipient.public_key] ) {
                MIHRSAPublicKey *publicKey = [[MIHRSAPublicKey alloc] initWithData:[NSData dataFromBase64String:savedMessage.recipient.public_key]];
                sendingText = [EncryptionUtil encryptText:message[@"text"] byPublicKey:publicKey];
                is_encrypted = @"1";
            }
            
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:[[MedXUser CurrentUser] accessToken] forKey:@"token"];
            [params setObject:[AppUtil getUTCDate:savedMessage.sent_at] forKey:@"sent_at"];
            [params setObject:savedMessage.recipient_id forKey:@"recipient_id"];
            [params setObject:savedMessage.app_message_id forKey:@"app_message_id"];
            [params setObject:sendingText forKey:@"text"];
            [params setObject:is_encrypted forKey:@"is_encrypted"];
            [params setObject:message[@"type"] forKey:@"type"];
            
            [[BackendBase sharedConnection] accessAPIbyPOST:@"messages/send" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
                NSLog(@"ChatService > sendTextMessage result: %@", result);
                if ( !error ) {
                    NSString *response = result[@"response"];
                    if ( [response isEqualToString:@"fail"] ) {
                        NSLog(@"Failed to send message. Status: %@", result[@"status"]);

                        [self handleMessageDeliveredForAppMessageId:app_message_id MessageStatus:MX_MESSAGE_STATUS_NOT_DELIVERED deliverCompletion:deliverCompletionHandler];
                        
                    } else {
                        NSLog(@"Successfully sent message. Message ID: %@", result[@"message"]);
                        
                        NSDictionary *info = @{@"app_message_id": message[@"app_message_id"],
                                               @"message_id"    : result[@"message"],
                                               @"status"        : @(MX_MESSAGE_STATUS_UNCOLLECTED)};
                        
                        [MXMessageUtil saveMessageByInfo:info attachment:nil completion:nil];
                    }
                    
                    [MXUserUtil updateUserDefaults:nil withLastLoginDate:nil];
                } else {
                    NSLog(@"ChatService > sendTextMessage Network ERROR - %@", error.description);
                    
                    [self handleMessageDeliveredForAppMessageId:app_message_id MessageStatus:MX_MESSAGE_STATUS_NOT_DELIVERED deliverCompletion:deliverCompletionHandler];
                }
            }];
        }
    }];
}

- (void)handleMessageDeliveredForAppMessageId:(NSString *)app_message_id MessageStatus:(int)message_status deliverCompletion:(void(^)(NSString *app_message_id, int message_status))deliverCompletionHandler {
    
    NSDictionary *info = @{@"app_message_id": app_message_id,
                           @"status"        : @(message_status)};
    
    [MXMessageUtil saveMessageByInfo:info attachment:nil completion:^(NSString *app_message_id, NSString *sharedKeyString, NSError *error) {
        if (app_message_id) {
            deliverCompletionHandler(app_message_id, message_status);
        }
    }];
}

- (void)sendPhotoMessage:(MXMessage *)message completion:(void(^)(NSString *app_message_id, int message_status))completionHandler {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:[[MedXUser CurrentUser] accessToken] forKey:@"token"];
    [params setObject:[AppUtil getUTCDate:message.sent_at] forKey:@"sent_at"];
    [params setObject:message.recipient_id forKey:@"recipient_id"];
    [params setObject:message.app_message_id forKey:@"app_message_id"];
    [params setObject:[message.type stringValue] forKey:@"type"];
    [params setObject:[message.width stringValue] forKey:@"width"];
    [params setObject:[message.height stringValue] forKey:@"height"];
    [params setObject:message.is_encrypted forKey:@"is_encrypted"];
    
    MXUser *recipient = [MXUser MR_findFirstByAttribute:@"user_id" withValue:message.recipient.user_id];
    if ( [message.is_encrypted isEqualToString:@"1"] && [AppUtil isNotEmptyString:recipient.public_key] ) {
        MedXUser *currentUser = [MedXUser CurrentUser];
        
        // Decrypts the encrypted shared AES key by current user's private RSA key
        NSString *sharedKeyString = [EncryptionUtil decryptText:message.text byPrivateKey:currentUser.privateKey];
        
        // Encrypts the shared AES key by recipient's public RSA key
        MIHRSAPublicKey *publicKey = [[MIHRSAPublicKey alloc] initWithData:[NSData dataFromBase64String:recipient.public_key]];
        NSString *encryptedSharedKeyString = [EncryptionUtil encryptText:sharedKeyString byPublicKey:publicKey];
        
        [params setObject:encryptedSharedKeyString forKey:@"text"];
    }
    
    [[BackendBase sharedConnection] accessAPIbyPOST:@"messages/send" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"ChatService > sendPhotoMessage result: %@", result);
        if ( !error ) {
            NSString *response = result[@"response"];
            if ( [response isEqualToString:@"fail"] ) {
                NSLog(@"Failed to send photo message. Status: %@", result[@"status"]);
                
                [self handleMessageDeliveredForAppMessageId:message.app_message_id MessageStatus:MX_MESSAGE_STATUS_NOT_DELIVERED deliverCompletion:completionHandler];
                
            } else {
                NSLog(@"Successfully sent message. Message ID: %@", result[@"message"]);
                
                NSDictionary *info = @{@"app_message_id": message.app_message_id,
                                       @"message_id"    : result[@"message"]};
                
                [MXMessageUtil saveMessageByInfo:info attachment:nil completion:^(NSString *app_message_id, NSString *sharedKeyString, NSError *error) {
                    if (completionHandler) completionHandler(app_message_id, MX_MESSAGE_STATUS_DELIVERED);
                }];
            }
            
            [MXUserUtil updateUserDefaults:nil withLastLoginDate:nil];
        } else {
            NSLog(@"ChatService > sendPhotoMessage Network ERROR - %@", error.description);
            
            [self handleMessageDeliveredForAppMessageId:message.app_message_id MessageStatus:MX_MESSAGE_STATUS_NOT_DELIVERED deliverCompletion:completionHandler];
        }
    }];
}

- (void)transferPhotoForMessage:(NSDictionary *)message_info completion:(void(^)(BOOL success,  NSString *errorStatus))completionHandler {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    MXMessage *message = [MXMessage MR_findFirstByAttribute:@"app_message_id" withValue:message_info[@"app_message_id"]];
    
    if ( [AppUtil isEmptyString:message.message_id]) {
        completionHandler(NO, @"message_id is not present.");
        return;
    }
    
    [params setObject:[[MedXUser CurrentUser] accessToken] forKey:@"token"];
    [params setObject:message.message_id forKey:@"message_id"];
    
    [[BackendBase sharedConnection] accessAPIbyPOST:@"messages/transfer_photo" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"ChatService > trasnferPhotoForMessage result: %@", result);
        if ( !error ) {
            NSString *response = result[@"response"];
            if ( [response isEqualToString:@"fail"] ) {
                NSLog(@"Failed to transfer photo. Status: %@", result[@"status"]);
                
                if (completionHandler) completionHandler(NO, result[@"status"]);
                
            } else {
                
                NSDictionary *info = @{@"app_message_id": message.app_message_id,
                                       @"status"        : @(MX_MESSAGE_STATUS_UNCOLLECTED)};
                
                [MXMessageUtil saveMessageByInfo:info attachment:nil completion:^(NSString *app_message_id, NSString *sharedKeyString, NSError *error) {
                    if (completionHandler) completionHandler(YES, nil);
                }];
            }
            
            [MXUserUtil updateUserDefaults:nil withLastLoginDate:nil];
        } else {
            NSLog(@"ChatService > sendTextMessage Network ERROR - %@", error.description);
            
            if (completionHandler) completionHandler(NO, nil);
        }
    }];
}


#pragma mark - Dropbox Methods

- (void)deleteReadMessagesFromServer:(NSArray *)readAppMessageIds completion:(void(^)(BOOL success))completionHandler {
    
    NSString *ids = [readAppMessageIds componentsJoinedByString:@","];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:[[MedXUser CurrentUser] accessToken] forKey:@"token"];
    [params setObject:ids forKey:@"app_message_ids"];
    
    [[BackendBase sharedConnection] accessAPIbyPOST:@"messages/delete" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"ChatService > deleteReadMessagesFromServer result: %@", result);

        if ( !error ) {
            NSString *response = result[@"response"];
            if ( [response isEqualToString:@"fail"] ) {
                NSLog(@"Failed to delete messages. Status: %@", result[@"status"]);
                if (completionHandler) completionHandler(NO);
                
            } else {
                NSLog(@"Successfully destroyed read messages from server: %@", ids);
                if (completionHandler) completionHandler(YES);
            }
            [MXUserUtil updateUserDefaults:nil withLastLoginDate:nil];
            
        } else {
            NSLog(@"ChatService > deleteReadMessagesFromServer Network ERROR - %@", error.description);
            if (completionHandler) completionHandler(NO);
        }
    }];
}

- (void)updateReceivedMessagesStatus:(NSString *)updatingStatus
                      forAppMessages:(NSArray *)app_message_ids
                          completion:(void(^)(BOOL success))completionHandler {
    
    NSString *ids = [app_message_ids componentsJoinedByString:@","];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:[[MedXUser CurrentUser] accessToken] forKey:@"token"];
    [params setObject:ids forKey:@"app_message_ids"];
    [params setObject:updatingStatus forKey:@"updating_status"];
    
    [[BackendBase sharedConnection] accessAPIbyPOST:@"messages/update_status" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"ChatService > updateReceivedMessagesStatus result: %@", result);
        
        if ( !error ) {
            NSString *response = result[@"response"];
            if ( [response isEqualToString:@"fail"] ) {
                NSLog(@"Failed to update messages status. Status: %@", result[@"status"]);
                if (completionHandler) completionHandler(NO);
                
            } else {
                NSLog(@"Successfully updated status of messages from server: %@", ids);
                if (completionHandler) completionHandler(YES);
            }
            [MXUserUtil updateUserDefaults:nil withLastLoginDate:nil];
            
        } else {
            NSLog(@"ChatService > updateReceivedMessagesStatus Network ERROR - %@", error.description);
            if (completionHandler) completionHandler(NO);
        }
    }];
}


#pragma mark - Timer Methods

- (void)startRegularCheck {
    timer = [NSTimer scheduledTimerWithTimeInterval:MX_DIALOG_CHECK_INTERVAL
                                             target:self
                                           selector:@selector(checkAllDialogs:)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)stopRegularCheck {
    [timer invalidate];
    timer = nil;
}


#pragma mark - Check and Handles new incoming & read sent messages

- (void)checkAllDialogs:(id)sender {
    
    if ( ![[MedXUser CurrentUser] accessToken] ) return;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[[MedXUser CurrentUser] accessToken] forKey:@"token"];
    
    [[BackendBase sharedConnection] accessAPIbyGET:@"check/all_dialogs" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"ChatService > checkAllDialogs result: %@", result);
        
        if ( !error ) {
            NSString *response = result[@"response"];
            if ( [response isEqualToString:@"fail"] ) {
                NSLog(@"Failed to check all dialogs. Status: %@", result[@"status"]);
                [self handleFailureInCheckAllDialgos];
            } else {
                [self handleIcomingMessages:result[@"incomings"] ReadSentMessages:result[@"reads"] Senders:result[@"senders"]];
            }
            [MXUserUtil updateUserDefaults:nil withLastLoginDate:nil];
            
        } else {
            NSLog(@"ChatService > checkAllDialogs Network ERROR - %@", error.description);
            [self handleFailureInCheckAllDialgos];
        }
    }];
}

- (void)handleFailureInCheckAllDialgos {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationChatDidFailInCheckAllDialogs
                                                        object:nil
                                                      userInfo:nil];
}

- (void)handleIcomingMessages:(NSArray *)incomingMessages ReadSentMessages:(NSArray *)readAppMessageIds Senders:(NSArray *)senders {
    if ( isCheckDialogInProgress ) return;
    
    isCheckDialogInProgress = YES;
    callback_count = 0;

    if ( [incomingMessages count] > 0 || [readAppMessageIds count] > 0 || [senders count] > 0 ) {
        
        [MXUserUtil saveUsers:senders forPrimaryUser:[[MedXUser CurrentUser] userId] completion:^(BOOL success, NSError *error) {
            if ( !error ) {
                [MXMessageUtil saveIncomingMessages:incomingMessages reads:readAppMessageIds completion:^(BOOL success, NSError *error) {
                    if ( !error ) {
                        
                        NSMutableArray *incomingAppMessageIds = [NSMutableArray array];
                        
                        // Mark new messages to sent status in server
                        for (NSDictionary *info in incomingMessages)
                            [incomingAppMessageIds addObject:info[@"app_message_id"]];
                        
                        if ( [incomingAppMessageIds count] > 0 ) {
                            NSString *status_sent = [@(MX_MESSAGE_STATUS_SENT) stringValue];
                            [self updateReceivedMessagesStatus:status_sent forAppMessages:incomingAppMessageIds completion:^(BOOL success) {
                                callback_count++;
                                if ( callback_count > 1 )
                                    [self postNotificationsAfterHandlingIcomingMessages:incomingMessages ReadSentMessages:readAppMessageIds];
                            }];
                        } else
                            callback_count++;
                        
                        // Delete read messages from server
                        if ( [readAppMessageIds count] > 0 ) {
                            [self deleteReadMessagesFromServer:readAppMessageIds completion:^(BOOL success) {
                                callback_count++;
                                
                                if ( callback_count > 1 )
                                    [self postNotificationsAfterHandlingIcomingMessages:incomingMessages ReadSentMessages:readAppMessageIds];
                            }];
                        } else
                            callback_count++;
                        
                        if (callback_count > 1)
                            [self postNotificationsAfterHandlingIcomingMessages:incomingMessages ReadSentMessages:readAppMessageIds];
                        
                    } else
                        [self postNotificationsAfterHandlingIcomingMessages:incomingMessages ReadSentMessages:readAppMessageIds];
                }];
            } else
                [self postNotificationsAfterHandlingIcomingMessages:incomingMessages ReadSentMessages:readAppMessageIds];
        }];
    } else
        [self postNotificationsAfterHandlingIcomingMessages:incomingMessages ReadSentMessages:readAppMessageIds];
}

- (void)postNotificationsAfterHandlingIcomingMessages:(NSArray *)incomingMessages ReadSentMessages:(NSArray *)readAppMessageIds {
    
    isCheckDialogInProgress = NO;
    
    if ( self.dialogRecipientId ) {
        NSMutableArray *newDialogAppMessageIds = [NSMutableArray array];
        
        for (NSDictionary *info in incomingMessages) {
            if ( [info[@"sender_id"] isEqualToString:self.dialogRecipientId] )
                [newDialogAppMessageIds addObject:info[@"app_message_id"]];
        }
        
        if ( [newDialogAppMessageIds count] > 0 || [readAppMessageIds count] > 0 )
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationChatDidReceiveNewDialogMessages
                                                                object:nil
                                                              userInfo:@{@"incomings": newDialogAppMessageIds,
                                                                         @"reads": readAppMessageIds}];
        
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationChatDidReceiveNewMessages
                                                            object:nil
                                                          userInfo:@{@"incomings": incomingMessages,
                                                                     @"reads":readAppMessageIds}];
        
        [[MedXUser CurrentUser] updateUserDialogsWithReadSentMessages:readAppMessageIds];
    }
}

@end
