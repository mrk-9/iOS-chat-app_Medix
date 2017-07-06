//
//  BackendBase.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BackendBase : NSObject

+ (BackendBase *)sharedConnection;

- (id)init;

- (void) accessAPIbyGET:(NSString *)apiPath
        Parameters:(NSDictionary *)params
 CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler;

- (void)accessAPIbyPOST:(NSString *)apiPath
             Parameters:(NSDictionary *)params
      CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler;

- (void)accessAPIbyPUT:(NSString *)apiPath
             Parameters:(NSDictionary *)params
      CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler;

- (void)accessAPIbyDELETE:(NSString *)apiPath
            Parameters:(NSDictionary *)params
     CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler;

- (void)uploadImagebyPost:(NSString *)apiPath
               Parameters:(NSDictionary *)params
                ImageData:(NSData *)imageData
                 filename:(NSString *)filename
      CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler;

- (void)uploadImagebyPost:(NSString *)apiPath
               Parameters:(NSDictionary *)params
                ImageData:(NSData *)imageData
                 filename:(NSString *)filename
                 observer:(id)observer
        CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler;

@end
