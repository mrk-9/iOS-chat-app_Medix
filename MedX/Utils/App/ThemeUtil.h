//
//  ThemeUtil.h
//  MedX
//
//  Created by Ping Ahn on 12/29/15.
//  Copyright © 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThemeUtil : NSObject

+ (void)initTheme;
+ (void)removeHeaderSpaceInTableView:(UITableView *)tableView;
+ (void)removeSeparatorForEmptyCellInTableView:(UITableView *)tableView;
+ (void)initTextFields:(NSArray *)textFields;
+ (void)applyRoundedBorderToImageView:(UIImageView *)imageView;
+ (UIColor *)avatarBGColorByIndex:(NSInteger)index;

@end
