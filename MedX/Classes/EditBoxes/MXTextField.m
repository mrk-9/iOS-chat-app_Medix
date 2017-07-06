//
//  MXTextField.m
//  MedX
//
//  Created by Anthony Zahra on 6/30/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXTextField.h"

@implementation MXTextField

static CGFloat leftMargin = 6;

- (CGRect)textRectForBounds:(CGRect)bounds
{
    bounds.origin.x += leftMargin;
    bounds.size.width -= 2*leftMargin;
    return bounds;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    bounds.origin.x += leftMargin;
    bounds.size.width -= 2*leftMargin;
    return bounds;
}

@end
