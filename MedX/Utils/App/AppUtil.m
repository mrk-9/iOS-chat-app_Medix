//
//  AppUtil.m
//  MedX
//
//  Created by Ping Ahn on 8/24/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "AppUtil.h"

@implementation AppUtil

#pragma mark - Basic Methods

+ (AppDelegate *)appDelegate {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

+ (void)setAppIconBadgeNumber:(int)number {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:number];
}

+ (UIStoryboard *)mainStoryboard {
    return [UIStoryboard storyboardWithName:@"Main" bundle:nil];
}

+ (id)instantiateViewControllerBy:(NSString *)storyBoardID {
    return [[self mainStoryboard] instantiateViewControllerWithIdentifier:storyBoardID];
}


#pragma mark - Log Methods

+ (void)log {
    
    NSLog(@"ImagesDir: %@", [AppUtil imagesPath]);
    
    NSLog(@"Users count: %lu", (unsigned long)[MXUser MR_countOfEntities]);
    NSLog(@"Messages count: %lu", (unsigned long)[MXMessage MR_countOfEntities]);
    NSLog(@"Relationships count: %lu", (unsigned long)[MXRelationship MR_countOfEntities]);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"MedXUser: %@", [MXUserUtil getUserInfoFromUserDefaults:defaults]);
    NSLog(@"Device Token: %@", [MXUserUtil getDeviceTokenFromUserDefaults:defaults]);
    NSArray *keys = [MXUserUtil getEncryptionKeysFromUserDefaults:defaults];
    if ( keys ) {
        NSLog(@"Public Key String: %@", keys[0]);
    } else
        NSLog(@"Encryption Keys: %@", keys);
    
    NSDate *lastLogin = [MXUserUtil getLastLoginFromUserDefaults:defaults];
    if (lastLogin)
        NSLog(@"Last login: %@", [self getSystemDateStringFromDate:lastLogin]);
    else
        NSLog(@"Last login: %@", lastLogin);
}


#pragma mark - Validation Methods

+ (BOOL)isEmptyObject:(id)obj {
    if (obj == nil)
        return YES;
    if ([obj isEqual:[NSNull null]])
        return YES;
    
    return NO;
}

+ (BOOL)isNotEmptyObject:(id)obj {
    if (obj == nil)
        return NO;
    if ([obj isEqual:[NSNull null]])
        return NO;
    
    return YES;
}

+ (BOOL)isEmptyString:(NSString *)string {
    if ([self isEmptyObject:string])
        return YES;
    
    NSString* result = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return [result isEqualToString:@""];
}

+ (BOOL)isNotEmptyString:(NSString *)string {
    if ([self isEmptyObject:string])
        return NO;
    
    NSString* result = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return ![result isEqualToString:@""];
}


#pragma mark - CoreData Methods

+ (NSString *)stringIdentifierByObject:(NSManagedObject *)object {
    
    return [[object.objectID URIRepresentation] absoluteString];
}


#pragma mark - DateTime Methods

+ (NSString *)timestampByDate:(NSDate *)date {
    
    return [NSString stringWithFormat:@"%f", [date timeIntervalSince1970] * 1000];
}

+ (NSString *)getUTCDate:(NSDate *)localDate {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *dateString = [dateFormatter stringFromDate:localDate];
    
    return dateString;
}

+ (NSDate *)getLocalDateFromString:(NSString *)dateString {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    
    return date;
}

+ (NSString *)getSystemDateStringFromDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    return dateString;
}


#pragma mark - File Methods

+ (NSString *)imagesPath {
    
    return [NSString stringWithFormat:@"%@/Documents/Images", NSHomeDirectory()];
}

+ (void)createImagesDirectory {
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:[self imagesPath] withIntermediateDirectories:YES attributes:nil error:&error];
}

+ (NSString *)imagePathWithFileName:(NSString *)filename {
    
    return [NSString stringWithFormat:@"%@/%@", [self imagesPath], filename];
}

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString {
    NSURL* URL= [NSURL fileURLWithPath: filePathString];
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

+ (void)dumpFilesInDirectoryPath:(NSString *)pathToDirectory {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *directory = [pathToDirectory stringByAppendingPathComponent:@"/"];
    NSError *error = nil;
    for (NSString *file in [fm contentsOfDirectoryAtPath:directory error:&error]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", pathToDirectory, file];
        BOOL success = [fm removeItemAtPath:filePath error:&error];
        if (!success || error) {
        }
    }
}

+ (NSArray *)getSpecialties {
    NSString* path    = [[NSBundle mainBundle] pathForResource:@"specialty_list" ofType:@"txt"];
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    
    return [content componentsSeparatedByString:@"\n"];
}


#pragma mark - Object Methods

+ (NSString *)classNameFromObject:(id)aObj {
    return [NSString stringWithFormat:@"%@", [aObj class]];
}

+ (NSString *)getJSONStringFromObject:(id)object {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return jsonString;
}

+ (id)getObjectFromJSONString:(NSString *)jsonString {
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id object = [NSJSONSerialization JSONObjectWithData:data  options:NSJSONReadingMutableContainers error:nil];
    
    return object;
}


#pragma mark - NSUserDefaults Methods

+ (void)setUserDefaults:(NSUserDefaults *)defaults withParams:(NSDictionary *)params {
    if ( !defaults ) defaults = [NSUserDefaults standardUserDefaults];
    
    for (NSString *key in params) {
        [defaults setObject:params[key] forKey:key];
    }
    [defaults synchronize];
}

+ (void)setUserDefaults:(NSUserDefaults *)defaults withValue:(id)obj forKey:(NSString *)key {
    if ( !defaults ) defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:obj forKey:key];
    [defaults synchronize];
}

+ (id)getValueFromUserDefaults:(NSUserDefaults *)defaults forKey:(NSString *)key {
    if ( !defaults ) defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults objectForKey:key];
}

+ (BOOL)checkUserDefaults:(NSUserDefaults *)defaults hasKey:(NSString *)key {
    if ( !defaults ) defaults = [NSUserDefaults standardUserDefaults];
    
    return !([defaults objectForKey:key] == nil);
}

+ (void)removeObjectsFromUserDefaults:(NSUserDefaults *)defaults forKeys:(NSArray *)keys {
    if ( !defaults ) defaults = [NSUserDefaults standardUserDefaults];
    
    for (NSString *k in keys) {
        [defaults removeObjectForKey:k];
    }
    [defaults synchronize];
}


#pragma mark - Phone number methods

+ (NSString *)formatOfficePhoneNumber:(NSString *)mobileNumber {
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    if ( [mobileNumber length] == 9)
        mobileNumber = [NSString stringWithFormat:@"0%@", mobileNumber];
    
    if ( [mobileNumber length] == 10 ) {
        mobileNumber = [NSString stringWithFormat:@"(%@) %@ %@",
                        [mobileNumber substringWithRange:NSMakeRange(0, 2)],
                        [mobileNumber substringWithRange:NSMakeRange(2, 4)],
                        [mobileNumber substringWithRange:NSMakeRange(6, 4)]];
    }
    
    return mobileNumber;
}

@end
