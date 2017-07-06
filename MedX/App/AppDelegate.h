//
//  AppDelegate.h
//  MedX
//
//  Created by Anthony Zahra on 6/11/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)registerForRemoteNotifications;
- (void)vibe:(id)sender;


#pragma mark - Logout/Wipe methods

- (void)logout;
- (void)wipe:(NSString *)access_token;

@end

