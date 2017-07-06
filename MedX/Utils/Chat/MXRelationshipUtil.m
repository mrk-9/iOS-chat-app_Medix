//
//  MXRelationshipUtil.m
//  MedX
//
//  Created by Ping Ahn on 8/26/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXRelationshipUtil.h"

@implementation MXRelationshipUtil

#pragma mark - CRUD Methods

+ (MXRelationship *)createRelationshipByInfo:(NSDictionary *)info forUserId:(NSString *)userId  inContext:(NSManagedObjectContext *)context {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"partner_id LIKE %@ AND user_id LIKE %@",
                                                            info[@"user_id"], userId];
    
    MXRelationship *relationship = [MXRelationship MR_findFirstWithPredicate:predicate inContext:context];
    
    if ([AppUtil isEmptyObject:relationship]) {
        relationship = [MXRelationship MR_createEntityInContext:context];
    }
    
    relationship.partner_id = info[@"user_id"];
    relationship.user_id = userId;
    relationship.user = [MXUserUtil findByUserId:userId inContext:context];
    
    return relationship;
}

+ (void)saveRelationshipByInfo:(NSDictionary *)info forUserId:(NSString *)userId {
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Save in local storage
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        [self createRelationshipByInfo:info forUserId:userId inContext:localContext];
        
    } completion:^(BOOL success, NSError *error) {
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}


#pragma mark - Find Methods

+ (MXRelationship *)findRelationshipByUserId:(NSString *)userId
                                   PartnerId:(NSString *)partnerId
                                   inContext:(NSManagedObjectContext *)context {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id LIKE %@ AND partner_id LIKE %@",
                                                              userId, partnerId];
    if ( context )
        return [MXRelationship MR_findFirstWithPredicate:predicate inContext:context];
    
    return [MXRelationship MR_findFirstWithPredicate:predicate];
}

+ (NSArray *)findPartnersByUserId:(NSString *)user_id {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id LIKE %@", user_id];
    
    NSArray *partners = [MXRelationship MR_findAllSortedBy:@"last_message_date"
                                                 ascending:NO withPredicate:predicate];
    
    NSMutableArray *partnerUsers = [NSMutableArray array];
    
    for (MXRelationship *rel in partners) {
        
        MXUser *u = [MXUserUtil findByUserId:rel.partner_id inContext:nil];
        
        if ( [AppUtil isNotEmptyObject:u] &&
            ([u.sentMessages count] > 0 || [u.receivedMessages count] > 0) )
            [partnerUsers addObject:u];
    }
    
    return partnerUsers;
}

@end
