//
//  UIColor+SLAddition.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (SLAddition)

+ (UIColor *)gradient:(double)percent top:(double)topX bottom:(double)bottomX init:(UIColor*)init goal:(UIColor*)goal;

@end
