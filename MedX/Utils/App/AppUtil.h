//
//  AppUtil.h
//  MedX
//
//  Created by Ping Ahn on 8/24/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppUtil : NSObject

#pragma mark - Basic Methods

+ (AppDelegate *)appDelegate;
+ (void)setAppIconBadgeNumber:(int)number;
+ (UIStoryboard *)mainStoryboard;
+ (id)instantiateViewControllerBy:(NSString *)storyBoardID;

#pragma mark - Log Methods

+ (void)log;


#pragma mark - Validation Methods

+ (BOOL)isEmptyObject:(id)obj;
+ (BOOL)isNotEmptyObject:(id)obj;
+ (BOOL)isEmptyString:(NSString *)string;
+ (BOOL)isNotEmptyString:(NSString *)string;


#pragma mark - CoreData Methods

+ (NSString *)stringIdentifierByObject:(NSManagedObject *)object ;


#pragma mark - DateTime Methods

+ (NSString *)timestampByDate:(NSDate *)date;
+ (NSString *)getUTCDate:(NSDate *)localDate;
+ (NSDate *)getLocalDateFromString:(NSString *)dateString;


#pragma mark - File Methods

+ (NSString *)imagesPath;
+ (void)createImagesDirectory;
+ (NSString *)imagePathWithFileName:(NSString *)filename;
+ (void)dumpFilesInDirectoryPath:(NSString *)pathToDirectory;

/**
 * Gets array of specialties from a text file
 */
+ (NSArray *)getSpecialties;


#pragma mark - Object Methods

+ (NSString *)classNameFromObject:(id)aObj;
+ (NSString *)getJSONStringFromObject:(id)object;
+ (id)getObjectFromJSONString:(NSString *)jsonString;

#pragma mark - NSUserDefaults Methods

+ (void)setUserDefaults:(NSUserDefaults *)defaults
             withParams:(NSDictionary *)params;
+ (void)setUserDefaults:(NSUserDefaults *)defaults
              withValue:(id)obj forKey:(NSString *)key;

/**
 * Prevent a file being backed up to iCloud or iTunes
 */
+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString;

+ (id)getValueFromUserDefaults:(NSUserDefaults *)defaults
                        forKey:(NSString *)key;
+ (BOOL)checkUserDefaults:(NSUserDefaults *)defaults
                   hasKey:(NSString *)key;
+ (void)removeObjectsFromUserDefaults:(NSUserDefaults *)defaults
                              forKeys:(NSArray *)keys;


#pragma mark - Phone number methods

/**
 * @return formatted office phone number e.g (xx) xxxx xxxx
 */
+ (NSString *)formatOfficePhoneNumber:(NSString *)mobileNumber;

@end
