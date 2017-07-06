//
//  MXRegisterController.h
//  MedX
//
//  Created by Anthony Zahra on 6/15/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXBaseController.h"

@interface MXRegisterController : MXBaseController

@property (nonatomic, strong) NSString      *registrationCode;
@property (nonatomic, strong) NSDictionary  *userInfo;

@end
