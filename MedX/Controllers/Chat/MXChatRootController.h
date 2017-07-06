//
//  MXChatRootController.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "SLPagingViewController.h"
#import "UIColor+SLAddition.h"

@protocol MXChatRootControllerDelegate <NSObject>

- (void)chatRootControllerDidClickBack;

@end

@interface MXChatRootController : SLPagingViewController

#pragma mark - Properties

@property NSInteger pageIndex;

@property (strong, nonatomic) MXUser *recipient;
@property (strong, nonatomic) UIImage* image;

@property (strong, nonatomic) id<MXChatRootControllerDelegate> delegate;
@property (strong, nonatomic) id<MXChatRootControllerDelegate> delegate2;

@end
