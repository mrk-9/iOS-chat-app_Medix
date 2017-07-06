//
//  AppDelegate.m
//  MedX
//
//  Created by Anthony Zahra on 6/11/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "AppDelegate.h"
#import "NotificationView.h"
#import "MXChatRootController.h"
#import "MXChatViewController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <AudioToolbox/AudioServices.h>
#import <AWSCore/AWSCore.h>
#import <AWSCognito/AWSCognito.h>


@interface AppDelegate () {

}

@property(nonatomic, strong) BackendBase *backend;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Initialize the Amazon Cognito credentials provider
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                          initWithRegionType:AWSRegionUSEast1
                                                          identityPoolId:AWS_COGNITO_POOL_ID];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest2 credentialsProvider:credentialsProvider];
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    
    // Override point for customization after application launch.
    
    [Fabric with:@[CrashlyticsKit]];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if( remoteNotification )
        [self didReceiveNotification:remoteNotification];
    
    _backend = [BackendBase sharedConnection];
    
    // Setup CoreData
    // [MagicalRecord setupCoreDataStackWithStoreNamed:@"chatModel"];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"chatModel"];
    
    // Creates images directory
    [AppUtil createImagesDirectory];
    
    [AppUtil log];
    
    // Initialize app theme
    [ThemeUtil initTheme];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self applicationWillTerminate:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if ( [[MedXUser CurrentUser] checkUserLoggedIn] ) {
        [[ChatService instance] checkAllDialogs:nil];
    }
}

- (void)registerForRemoteNotifications {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveRemoteNotification userInfo=%@", userInfo);
    
    [self didReceiveNotification:userInfo];
}

- (void)vibe:(id)sender {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[[[deviceToken description]
                                stringByReplacingOccurrencesOfString: @"<" withString: @""]
                               stringByReplacingOccurrencesOfString: @">" withString: @""]
                              stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    NSLog(@"%@", token);
    
    if ( token ) {
        
        MedXUser *currentUser = [MedXUser CurrentUser];
        if ( [currentUser checkUserLoggedIn] )
            [currentUser registerDeviceToken:token completion:nil];
        
        [MXUserUtil updateUserDefaults:nil withDeviceToken:token];
    }
}

#pragma mark - Message Notification

- (void)didReceiveNotification:(NSDictionary *)userInfo {
    NSString *alert = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    
    NSString *noteType = [userInfo objectForKey:@"type"];
    if ( [AppUtil isEmptyObject:noteType] ) return;
    
    /////////      Remote Notification For New Message       /////////
    if ( [noteType isEqualToString:MX_REMOTE_NOTE_TYPE_NEW_MESSAGE] ) {
        
        NSString *senderId = [userInfo objectForKey:@"senderId"];
        NSString *dialogRecipientId = [[ChatService instance] dialogRecipientId];
        NSString *dialogViewName = [[ChatService instance] dialogViewName];
        BOOL bHasToShowCurtainNotification = NO;
        BOOL bHasToCheckNewMessagesFromServer = YES;
        
        if ( [dialogViewName isEqualToString:MX_DIALOG_VIEW_INDEX] ) {
            // Vibrates twice
            for (int i = 1; i < 4; i++) {
                [self performSelector:@selector(vibe:) withObject:self afterDelay:i *.3f];
            }
            
        } else if ( [dialogViewName isEqualToString:MX_DIALOG_VIEW_SETTINGS] ) {
            bHasToShowCurtainNotification = YES;
            
        } else if ( [dialogViewName isEqualToString:MX_DIALOG_VIEW_CHAT] ) {
            
            if ( [senderId isEqualToString:dialogRecipientId] )
                bHasToCheckNewMessagesFromServer = NO;
            else
                bHasToShowCurtainNotification = YES;
        }
        
        if ( bHasToShowCurtainNotification )
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"New Message"
                                                           description:alert
                                                                  type:TWMessageBarMessageTypeInfo
                                                              duration:10.0];
        
        if ( bHasToCheckNewMessagesFromServer )
            [[ChatService instance] checkAllDialogs:nil];
        
    } else if ( [noteType isEqualToString:MX_REMOTE_NOTE_TYPE_READ_SENT_MESSAGE] ) {
        [[ChatService instance] checkAllDialogs:nil];
    }
}

#pragma mark - Logout/Wipe methods

- (void)logout {
    [MXUserUtil removeUserParamsFromUserDefaults:nil];
    
    [[ChatService instance] setDialogRecipientId:nil];
    [[ChatService instance] setDialogViewName:nil];
    
    [[MedXUser CurrentUser] unset];
    
    UIViewController *mainController = [AppUtil instantiateViewControllerBy:@"mainController"];
    self.window.rootViewController = mainController;
}

- (void)wipe:(NSString *)access_token {
    if ( !access_token ) return;
    
    NSDictionary *params = @{@"token": access_token};
    [[BackendBase sharedConnection] accessAPIbyPOST:@"users/unset_wipe" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSString* response = result[@"response"];
        if ( [response isEqualToString:@"success"] ) {
            [self logout];
            
            [MXUserUtil removeEncryptionKeysFromUserDefaults:nil];
            
            UIApplication *application = [UIApplication sharedApplication];
            __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
                [application endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            }];
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                [MXUser MR_truncateAllInContext:localContext];
                [MXMessage MR_truncateAllInContext:localContext];
                [MXRelationship MR_truncateAllInContext:localContext];
                
            } completion:^(BOOL contextDidSave, NSError *error) {
                [application endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            }];
        }
    }];
}

@end
