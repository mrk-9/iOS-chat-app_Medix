//
//  MXMessage.h
//  MedX
//
//  Created by Ping Ahn on 9/28/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MXUser;

@interface MXMessage : NSManagedObject

@property (nonatomic, retain) NSString * app_message_id;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * message_id;
@property (nonatomic, retain) NSString * recipient_id;
@property (nonatomic, retain) NSString * sender_id;
@property (nonatomic, retain) NSDate * sent_at;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSString * is_encrypted;
@property (nonatomic, retain) MXUser *recipient;
@property (nonatomic, retain) MXUser *sender;

@end
