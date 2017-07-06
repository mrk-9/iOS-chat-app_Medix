//
//  NotificationView.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NotificationView;

@protocol NotificationDelegate

-(void) openMessage : (NSDictionary*) messageInfo;

@end

@interface NotificationView : UIView

@property NSDictionary *messageInfo;
@property (nonatomic, assign) id delegate;
@property BOOL isShowing;

-(void) showMessage: (NSString*) msg;
-(void) hideNotification;

@end
