//
//  MXImageBrowser.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//


#import "MXImageBrowser.h"

#define browserImageTag 1000

static UIImageView *orginImageView;

@implementation MXImageBrowser

+(void)showImage:(UIImageView *)avatarImageView{
    UIImage *image = avatarImageView.image;
    orginImageView = avatarImageView;
    
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *backgroundView = [[UIView alloc]initWithFrame:
                              CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    CGRect oldframe = [avatarImageView convertRect: avatarImageView.bounds toView: window];
    
    backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent: 0.7];
    backgroundView.alpha = 1.0f;
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:oldframe];
    imageView.image = image;
    imageView.tag = browserImageTag;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    
    [backgroundView addSubview: imageView];
    [window addSubview: backgroundView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideImage:)];
    [backgroundView addGestureRecognizer: tap];
    
    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame=CGRectMake(0,([UIScreen mainScreen].bounds.size.height-image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width)/2, [UIScreen mainScreen].bounds.size.width, image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width);
        backgroundView.alpha=1;
    } completion:^(BOOL finished) {
        
    }];
}

+(void)hideImage: (UITapGestureRecognizer*)tap{
    UIView *backgroundView = tap.view;
    UIImageView *imageView = (UIImageView*)[tap.view viewWithTag:browserImageTag];
    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame = [orginImageView convertRect:orginImageView.bounds toView:[UIApplication sharedApplication].keyWindow];
    } completion:^(BOOL finished) {
        [backgroundView removeFromSuperview];
        backgroundView.alpha = 0;
    }];
}


@end
