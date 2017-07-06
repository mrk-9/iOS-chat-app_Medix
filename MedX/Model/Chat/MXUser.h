//
//  MXUser.h
//  MedX
//
//  Created by Ping Ahn on 11/13/15.
//  Copyright © 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MXMessage, MXRelationship;

NS_ASSUME_NONNULL_BEGIN

@interface MXUser : NSManagedObject

#pragma mark - Attributes methods

- (NSString *)fullName;
- (NSString *)fullNameWithSalutation;
- (NSString *)shortNameWithSalutation;
- (NSString *)initials;
- (NSString *)contactIdentifier;
- (NSInteger)avtarBGColorIndex;


#pragma mark - Flag methods

- (BOOL)hasInstalledApp;
- (BOOL)isVerified;

@end

NS_ASSUME_NONNULL_END

#import "MXUser+CoreDataProperties.h"
