//
//  MXRelationshipUtil.h
//  MedX
//
//  Created by Ping Ahn on 8/26/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MXRelationshipUtil : NSObject

#pragma mark - CRUD Methods

+ (MXRelationship *)createRelationshipByInfo:(NSDictionary *)info
                                   forUserId:(NSString *)userId
                                   inContext:(NSManagedObjectContext *)context;

+ (void)saveRelationshipByInfo:(NSDictionary *)info
                     forUserId:(NSString *)userId;


#pragma mark - Find Methods

+ (NSArray *)findPartnersByUserId:(NSString *)user_id;

+ (MXRelationship *)findRelationshipByUserId:(NSString *)userId
                                   PartnerId:(NSString *)partnerId
                                   inContext:(NSManagedObjectContext *)context;

@end
