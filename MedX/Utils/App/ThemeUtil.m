//
//  ThemeUtil.m
//  MedX
//
//  Created by Ping Ahn on 12/29/15.
//  Copyright © 2015 Hugo. All rights reserved.
//

#import "ThemeUtil.h"

@implementation ThemeUtil

+ (void)initTheme {
    // Navigation bar theme
    [[UINavigationBar appearance] setBarTintColor:RGBHEX(0x53BEAC, 1.f)];
    [[UINavigationBar appearance] setTintColor:RGBHEX(0xFFFFFF, 1.f)];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: RGBHEX(0xFFFFFF, 1.f)}];
}

+ (void)removeHeaderSpaceInTableView:(UITableView *)tableView {
    CGRect frame       = tableView.tableHeaderView.frame;
    frame.size.height  = 1;
    UIView *headerView = [[UIView alloc] initWithFrame:frame];
    
    [tableView setTableHeaderView:headerView];
}

+ (void)removeSeparatorForEmptyCellInTableView:(UITableView *)tableView {
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

+ (void)initTextFields:(NSArray *)textFields {
    for (UITextField *field in textFields) {
        [field.layer setBorderWidth:1.0f];
        [field.layer setBorderColor:RGBHEX(0xE6E6E6, 1.0).CGColor];
    }
}

+ (void)applyRoundedBorderToImageView:(UIImageView *)imageView {
    [[imageView layer] setBorderWidth:0.5f];
    [[imageView layer] setBorderColor:[[UIColor clearColor] CGColor]];
    [[imageView layer] setCornerRadius:CGRectGetWidth([imageView frame]) / 2];
    [[imageView layer] setMasksToBounds:YES];
}

+ (UIColor *)avatarBGColorByIndex:(NSInteger)index {
    NSArray *colors = @[
                        [UIColor colorWithRed:204.f / 255.f green:148.f / 255.f blue:102.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:187.f / 255.f green:104.f / 255.f blue:62.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:145.f / 255.f green:78.f / 255.f blue:48.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:122.f / 255.f green:63.f / 255.f blue:41.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:80.f / 255.f green:46.f / 255.f blue:27.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:57.f / 255.f green:45.f / 255.f blue:19.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:37.f / 255.f green:38.f / 255.f blue:13.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:23.f / 255.f green:31.f / 255.f blue:10.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:6.f / 255.f green:19.f / 255.f blue:10.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:13.f / 255.f green:4.f / 255.f blue:16.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:27.f / 255.f green:12.f / 255.f blue:44.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:18.f / 255.f green:17.f / 255.f blue:64.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:20.f / 255.f green:42.f / 255.f blue:77.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:18.f / 255.f green:55.f / 255.f blue:68.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:18.f / 255.f green:68.f / 255.f blue:61.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:19.f / 255.f green:73.f / 255.f blue:26.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:13.f / 255.f green:48.f / 255.f blue:15.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:44.f / 255.f green:165.f / 255.f blue:137.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:137.f / 255.f green:181.f / 255.f blue:48.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:208.f / 255.f green:204.f / 255.f blue:78.f / 255.f alpha:1.f],
                        [UIColor colorWithRed:227.f / 255.f green:162.f / 255.f blue:150.f / 255.f alpha:1.f]
                        ];
    return [colors objectAtIndex:index];
}

@end
