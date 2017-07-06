//
//  BackendBase.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//


#import "BackendBase.h"
#import <AFNetworking/AFNetworking.h>

static BackendBase   *sharedConnection;

@implementation BackendBase

+ (BackendBase *)sharedConnection {
    if (sharedConnection == nil)
        sharedConnection = [BackendBase new];
    return sharedConnection;
}

- (id)init {
    self = [super init];
    return self;
}


- (void)accessAPIbyGET:(NSString *)apiPath
        Parameters:(NSDictionary *)params
 CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:BaseURL]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager GET:apiPath parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        id response = [NSJSONSerialization JSONObjectWithData: responseObject
                                                      options:NSJSONReadingMutableContainers error:nil];
        if ([self isRemoteWipeSetWithResponse:response])
            [self doRemoteWipeWithResponse:response];
        else if ([self isSessionExpiredWithResponse:response])
            [[AppUtil appDelegate] logout];
        else
            handler(response, nil, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        handler(nil, nil, error);
    }];
    
}

- (void)accessAPIbyPOST:(NSString *)apiPath
        Parameters:(NSDictionary *)params
 CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:BaseURL]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:apiPath parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        id response = [NSJSONSerialization JSONObjectWithData:responseObject
                                                      options:NSJSONReadingMutableContainers error:nil];
        if ([self isRemoteWipeSetWithResponse:response])
            [self doRemoteWipeWithResponse:response];
        else if ([self isSessionExpiredWithResponse:response])
            [[AppUtil appDelegate] logout];
        else
            handler(response, nil, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        handler(nil, nil, error);
    }];
}

- (void)accessAPIbyPUT:(NSString *)apiPath
             Parameters:(NSDictionary *)params
      CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler {
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:BaseURL]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager PUT:apiPath parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        
        id response = [NSJSONSerialization JSONObjectWithData: responseObject options:NSJSONReadingMutableContainers error:nil];
        
        handler(response, nil, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        handler(nil, nil, error);
    }];
}

- (void)accessAPIbyDELETE:(NSString *)apiPath
             Parameters:(NSDictionary *)params
      CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler {
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:BaseURL]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager DELETE:apiPath parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        
        id response = [NSJSONSerialization JSONObjectWithData: responseObject options:NSJSONReadingMutableContainers error:nil];
        
        handler(response, nil, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        handler(nil, nil, error);
    }];
}

- (void)uploadImagebyPost:(NSString *)apiPath
               Parameters:(NSDictionary *)params
                    ImageData:(NSData *)imageData
                 filename:(NSString *)filename
        CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler {
        
    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"img.jpg\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];    
    [body appendData:imageData];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"api\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"" dataUsingEncoding:NSUTF8StringEncoding]];

    
    for (NSString *key in params) {
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[params objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", BaseURL, apiPath]]];
    [request setHTTPMethod:@"POST"];
    
    [request setHTTPBody:body];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
       if (data != nil) {
           
           NSError *myError = nil;
           NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data
                                                                  options:NSJSONReadingMutableLeaves error:&myError];
           
           handler(result, data, connectionError);
       } else {
           handler(nil, nil, nil);
       }
   }];
}

- (void)uploadImagebyPost:(NSString *)apiPath
               Parameters:(NSDictionary *)params
                ImageData:(NSData *)imageData
                 filename:(NSString *)filename
                 observer:(id)observer
        CompletionHandler:(void (^)(NSDictionary *result, NSData *data, NSError *error))handler {
    
    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"img\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"api\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"" dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    for (NSString *key in params) {
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[params objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", BaseURL, apiPath]]];
    [request setHTTPMethod:@"POST"];
    
    [request setHTTPBody:body];
    
    NSProgress *progress;
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:BaseURL]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSURLSessionTask *uploadTask = [manager uploadTaskWithRequest:request fromData:body progress:&progress
                                                 completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                        if (!error) {
                                            id responseData = [NSJSONSerialization JSONObjectWithData: responseObject options:NSJSONReadingMutableContainers error:nil];
                                            handler(responseData, nil, nil);
                                        } else {
                                            handler(nil, nil, error);
                                        }
                                    }];
    [uploadTask resume];
    [progress addObserver:observer forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:NULL];
}



#pragma mark - Check remote wipe & invalid token status

// Check if remote-wipe parameter is set
- (BOOL)isRemoteWipeSetWithResponse:(NSDictionary *)response {
    BOOL isRemoteWipeSet = [response[@"wipe"] integerValue] == 1;
    return isRemoteWipeSet;
}

- (void)doRemoteWipeWithResponse:(NSDictionary *)response {
    NSString *token = nil;
    if ([MedXUser CurrentUser] && [[MedXUser CurrentUser] accessToken])
        token = [[MedXUser CurrentUser] accessToken];
    else if (response[@"user"] && response[@"user"][@"access_token"])
        token = response[@"user"][@"access_token"];
    [[AppUtil appDelegate] wipe:token];
}

// Check if session is expired due to invalid token
- (BOOL)isSessionExpiredWithResponse:(NSDictionary *)response {
    BOOL isExpired = [response[@"response"] isEqualToString:@"fail"] && [response[@"status"] isEqualToString:@"invalid_token"];
    return isExpired;
}


@end

