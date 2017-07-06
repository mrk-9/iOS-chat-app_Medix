//
//  MXDirectoryProfileVC.h
//  MedX
//
//  Created by Ping Ahn on 10/7/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXBaseController.h"

@class MXDirectoryProfileVC;

@protocol MXDirectoryProfileVCDelegate <NSObject>

- (void)directoryProfileVCDidClickChatUser:(MXDirectoryProfileVC *)profileVC;

@end


@interface MXDirectoryProfileVC : MXBaseController

@property (strong, nonatomic) NSString *user_id;
@property (strong, nonatomic) id<MXDirectoryProfileVCDelegate> delegate;

@end
