//
//  ChatService.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ChatService : NSObject

#pragma mark - Properties

@property(strong, nonatomic) NSString *dialogRecipientId;
@property(strong, nonatomic) NSString *dialogViewName;


#pragma mark - Init Methods

+ (instancetype)instance;
- (void)logout;


#pragma mark - Sending Messages

- (void)sendTextMessage:(id)message
   localStoreCompletion:(void(^)(NSString *app_message_id, NSError *error))localStoreCompletionHandler
      deliverCompletion:(void(^)(NSString *app_message_id, int message_status))deliverCompletionHandler;

- (void)sendPhotoMessage:(MXMessage *)message
              completion:(void(^)(NSString *app_message_id, int message_status))completionHandler;

- (void)transferPhotoForMessage:(NSDictionary *)message_info
                     completion:(void(^)(BOOL success,  NSString *errorStatus))completionHandler;


#pragma mark - Dropbox Methods

- (void)deleteReadMessagesFromServer:(NSArray *)readAppMessageIds
                          completion:(void(^)(BOOL success))completionHandler;

- (void)updateReceivedMessagesStatus:(NSString *)updatingStatus
                       forAppMessages:(NSArray *)app_message_ids
                           completion:(void(^)(BOOL success))completionHandler;


#pragma mark - Timer Methods

- (void)startRegularCheck;
- (void)stopRegularCheck;


#pragma mark - Check and Handles new incoming & read sent messages

- (void)checkAllDialogs:(id)sender;

@end
