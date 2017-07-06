//
//  MXUser+CoreDataProperties.h
//  MedX
//
//  Created by Ping Ahn on 11/13/15.
//  Copyright © 2015 Hugo. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "MXUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface MXUser (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *about;
@property (nullable, nonatomic, retain) NSString *address;
@property (nullable, nonatomic, retain) NSString *first_name;
@property (nullable, nonatomic, retain) NSString *last_name;
@property (nullable, nonatomic, retain) NSString *locations;
@property (nullable, nonatomic, retain) NSString *preferred_first_name;
@property (nullable, nonatomic, retain) NSString *public_key;
@property (nullable, nonatomic, retain) NSString *salutation;
@property (nullable, nonatomic, retain) NSString *specialty;
@property (nullable, nonatomic, retain) NSString *user_id;
@property (nullable, nonatomic, retain) NSNumber *status;
@property (nullable, nonatomic, retain) NSSet<MXRelationship *> *partners;
@property (nullable, nonatomic, retain) NSSet<MXMessage *> *receivedMessages;
@property (nullable, nonatomic, retain) NSSet<MXMessage *> *sentMessages;

@end

@interface MXUser (CoreDataGeneratedAccessors)

- (void)addPartnersObject:(MXRelationship *)value;
- (void)removePartnersObject:(MXRelationship *)value;
- (void)addPartners:(NSSet<MXRelationship *> *)values;
- (void)removePartners:(NSSet<MXRelationship *> *)values;

- (void)addReceivedMessagesObject:(MXMessage *)value;
- (void)removeReceivedMessagesObject:(MXMessage *)value;
- (void)addReceivedMessages:(NSSet<MXMessage *> *)values;
- (void)removeReceivedMessages:(NSSet<MXMessage *> *)values;

- (void)addSentMessagesObject:(MXMessage *)value;
- (void)removeSentMessagesObject:(MXMessage *)value;
- (void)addSentMessages:(NSSet<MXMessage *> *)values;
- (void)removeSentMessages:(NSSet<MXMessage *> *)values;

@end

NS_ASSUME_NONNULL_END
