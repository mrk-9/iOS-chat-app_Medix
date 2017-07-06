//
//  MXChatController.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXBaseController.h"
#import "MXChatRootController.h"
#import "IQTextView.h"

@interface MXChatController : MXBaseController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MXChatRootControllerDelegate>

@end
