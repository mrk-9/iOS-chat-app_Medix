//
//  MXLocationView.h
//  MedX
//
//  Created by Anthony Zahra on 6/24/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MXSettingsController.h"

@interface MXLocationView : UIView

#pragma mark - Properties & Blocks

@property (nonatomic, strong) void (^onDismiss)(NSDictionary*);
@property (nonatomic, strong) MXSettingsController *parentVC;

@end
