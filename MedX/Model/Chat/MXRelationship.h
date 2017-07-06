//
//  MXRelationship.h
//  MedX
//
//  Created by Ping Ahn on 8/31/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MXUser;

@interface MXRelationship : NSManagedObject

@property (nonatomic, retain) NSString * partner_id;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) NSDate * last_message_date;
@property (nonatomic, retain) MXUser *user;

@end
