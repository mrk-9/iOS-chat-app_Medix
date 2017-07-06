//
//  MXMomsCell.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXDoctorsCell.h"

@interface MXDoctorsCell () {
    __weak IBOutlet UILabel *lblUsername;
    __weak IBOutlet UILabel *lblDistance;
    __weak IBOutlet UILabel *lblSpecialty;
    __weak IBOutlet UILabel *lblAddress;
}

@end

@implementation MXDoctorsCell

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setupCell:(NSDictionary *)info {
    _doctorsInfo = info;
    
    lblUsername.text = [NSString stringWithFormat:@"%@, %@", _doctorsInfo[@"last_name"], _doctorsInfo[@"preferred_first_name"]];
    
    if ( [AppUtil isEmptyString:_doctorsInfo[@"public_key"]] ) {
        lblUsername.textColor = RGBHEX(0xDB5A76, 1.f);
    } else {
        lblUsername.textColor = [UIColor blackColor];
    }
    
    lblSpecialty.text  = _doctorsInfo[@"specialty"];
    
    if ([AppUtil isEmptyObject:_doctorsInfo[@"distance"]])
        lblDistance.text = @"";
    else
        lblDistance.text = [NSString stringWithFormat:@"%.2fkm", [_doctorsInfo[@"distance"] floatValue]];
    
    if ([AppUtil isNotEmptyObject:_doctorsInfo[@"address"]])
        lblAddress.text = _doctorsInfo[@"address"];
    else
        lblAddress.text = @"";
}

@end
