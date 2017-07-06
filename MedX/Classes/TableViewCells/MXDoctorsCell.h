//
//  MXDoctorsCell.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MXDoctorsCell : UITableViewCell

@property (nonatomic, strong) NSDictionary *doctorsInfo;

-(void) setupCell : (NSDictionary*)info;

@end
