//
//  MXChatCell.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//


#import "MXChatCell.h"
#import "AsyncImageView.h"
#import "MXImageBrowser.h"
#import "MXOverlayProgressView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AWSS3.h"
#import "JTSImageViewController.h"
#import "MXChatController.h"
#import "MXChatRootController.h"

#define kBubbleMarginLeftMin        130
#define kBubbleMarginBottom         15
#define kPhotoBubblePaddingTop      12
#define kTextBubblePaddingTop       3
#define kBubblePaddingLeft          12
#define kBubblePaddingBottom        20
#define kBubblePaddingRight         (12+6) // 6: The width of the bottom-right empty space of bubble
#define kBubbleMinWidth             60

static CGFloat kBubbleFontSize = 15.f;

@interface MXChatCell() {
    AsyncImageView *profileImageView;
    UILabel *lblTime;
    UIImageView *bubbleImageView;
    UIImageView *readStatusView;
    
    UIView *containerView;
    UITextView *messageTextView;
    UIImageView *thumbnailView;
    BOOL sentMessage;
    BOOL textMessage;
    
    MXOverlayProgressView *progressView;
    AWSS3TransferManagerUploadRequest *uploadRequest;
    
    NSTimer *timer;
    CGFloat transferStatus;
    
    MedXUser *currentUser;
}

@end


@implementation MXChatCell

#pragma mark - Lifecycle methods

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)layoutSubviews {
    CGSize cellSize = self.bounds.size, bubbleSize = [MXChatCell bubbleSizeFromMessageInfo:_messageInfo];
    
    // ===================     Bubble Image   ============================
    CGRect bubbleRect = CGRectZero;
    if ( sentMessage )
        bubbleRect = CGRectMake(cellSize.width-bubbleSize.width, 0, bubbleSize.width, bubbleSize.height);
    else
        bubbleRect = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height);
    [bubbleImageView setFrame:bubbleRect];
    
    // ===================    Container View   ==========================
    CGRect contentFrame = CGRectZero;
    contentFrame.origin.x    = bubbleRect.origin.x + (sentMessage ? kBubblePaddingLeft : kBubblePaddingRight);
    contentFrame.origin.y    = bubbleRect.origin.y + (textMessage ? kTextBubblePaddingTop :
                                                      kPhotoBubblePaddingTop);
    contentFrame.size.width  = bubbleSize.width - (kBubblePaddingLeft+kBubblePaddingRight);
    contentFrame.size.height = bubbleSize.height - (textMessage ? kTextBubblePaddingTop :
                                                    kBubblePaddingBottom+kPhotoBubblePaddingTop);
    [containerView setFrame:contentFrame];
    
    // ===================    Photo & Message TextView   ===============
    if ( [_messageInfo[@"type"] integerValue] == MX_MESSAGE_TYPE_PHOTO ) {
        [thumbnailView setFrame:containerView.bounds];
        [progressView setFrame:thumbnailView.bounds];
    } else {
        [messageTextView setFrame:containerView.bounds];
    }
    
    // ===================    Time Label & Read Status View ============
    CGRect timeRect   = CGRectZero;
    timeRect.size     = [lblTime sizeThatFits:CGSizeMake(kBubbleMinWidth, 15)];
    timeRect.origin.x = sentMessage ? bubbleRect.origin.x + kBubblePaddingLeft
                                    : bubbleSize.width - kBubblePaddingLeft - timeRect.size.width;
    timeRect.origin.y = bubbleRect.size.height - kBubblePaddingBottom
                        + (kBubblePaddingBottom-timeRect.size.height)/2;
    
    if ( sentMessage && readStatusView.image ) {
        CGRect readStatusRect   = readStatusView.frame;
        readStatusRect.origin.x = timeRect.origin.x;
        readStatusRect.origin.y = timeRect.origin.y;
        readStatusRect.size     = CGSizeMake(timeRect.size.height, timeRect.size.height);
        [readStatusView setFrame:readStatusRect];
        
        timeRect.origin.x += readStatusRect.size.width + 2;
    }
    [lblTime setFrame:timeRect];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
            Message:(NSDictionary *)message_info ProfileImage:(UIImage*)image {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if ( self ) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.messageInfo = [NSMutableDictionary dictionaryWithDictionary:message_info];
        self.profileImage = image;
        
        currentUser = [MedXUser CurrentUser];
        sentMessage = [_messageInfo[@"sender_id"] isEqualToString:[currentUser userId]];
        textMessage = [_messageInfo[@"type"] integerValue] == MX_MESSAGE_TYPE_TEXT;
        
        // =================    Bubble Image   =================
        bubbleImageView       = [[UIImageView alloc] init];
        bubbleImageView.image = [self cellBackgroundImage];
        [self.contentView addSubview:bubbleImageView];
        
        // =================   Container   =====================
        containerView = [[UIView alloc] init];
        containerView.backgroundColor        = [UIColor clearColor];
        containerView.layer.masksToBounds    = YES;
        containerView.layer.cornerRadius     = 5.0f;
        containerView.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContentClicked)];
        [containerView addGestureRecognizer:tapGesture];
        [containerView setBackgroundColor:[UIColor clearColor]];
        [self.contentView addSubview:containerView];
        
        // =================    Photo/Message   ===============
        messageTextView = [[UITextView alloc] init];
        messageTextView.scrollEnabled   = NO;
        messageTextView.editable        = NO;
        messageTextView.backgroundColor = [UIColor clearColor];
        
        if ( [_messageInfo[@"type"] integerValue] == MX_MESSAGE_TYPE_PHOTO ) {
            thumbnailView = [[UIImageView alloc] init];
            thumbnailView.clipsToBounds = YES;
            if ([MXMessageUtil checkLocalImageExistsForMessage:_messageInfo])
                thumbnailView.image = [MXMessageUtil imageOfMessage:_messageInfo];
            else
                thumbnailView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            progressView = [[MXOverlayProgressView alloc] init];
            [thumbnailView addSubview:progressView];
            [containerView addSubview:thumbnailView];
            
            if ( sentMessage && [AppUtil isEmptyObject:_messageInfo[@"status"]] )
                [self uploadAttachment];
            else if ( !sentMessage &&
                     [AppUtil isEmptyObject:_messageInfo[@"filename"]] &&
                     [AppUtil isNotEmptyObject:_messageInfo[@"url"]] )
                [self downloadAttachmentFromServer];
            else
                [self hideProgressOverlay];
            
        } else {
            messageTextView.textColor = [self textMessageColor];
            if ( [AppUtil isEmptyString:_messageInfo[@"text"]] ) {
                messageTextView.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:kBubbleFontSize];
                messageTextView.text = MX_MESSAGE_TEXT_SENT_FOR_DIFFERENT_DEVICE;
            } else {
                messageTextView.text = _messageInfo[@"text"];
                messageTextView.font = [UIFont fontWithName:@"HelveticaNeue" size:kBubbleFontSize];
            }
            [containerView addSubview:messageTextView];
        }
        
        // ================= Time Label & Read Status =======
        lblTime = [[UILabel alloc] init];
        lblTime.font          = [UIFont fontWithName:@"HelveticaNeue" size:11.f];
        lblTime.textAlignment = sentMessage ? NSTextAlignmentLeft : NSTextAlignmentRight;
        lblTime.textColor     = [self timeLabelColor];

        static NSDateFormatter *dateFormatter;
        if ( dateFormatter == nil ) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.timeZone   = [NSTimeZone systemTimeZone];
            dateFormatter.dateFormat = @"hh:mm a";
        }
        lblTime.text = [dateFormatter stringFromDate:_messageInfo[@"sent_at"]];
        [self.contentView addSubview:lblTime];
        
        [self setReadStatus];
    }

    return self;
}


#pragma mark - Cell configuration

- (void)setupCell:(NSDictionary *)message_info {
    NSInteger oldStatus = [_messageInfo[@"status"] integerValue];
    self.messageInfo = [NSMutableDictionary dictionaryWithDictionary:message_info];
    [self setReadStatus];
    
    if ( [_messageInfo[@"type"] integerValue] == MX_MESSAGE_TYPE_PHOTO ) {
        BOOL bExists = [MXMessageUtil checkLocalImageExistsForMessage:_messageInfo];
        if ( [AppUtil isNotEmptyString:_messageInfo[@"url"]] && !bExists ) {
            progressView.hidden = NO;
            [self downloadAttachmentFromServer];
        }
    }
    
    if ( [AppUtil isNotEmptyObject:_messageInfo[@"status"]] ) {
        if ( [_messageInfo[@"status"] integerValue] == MX_MESSAGE_STATUS_NOT_DELIVERED ) {
            // Resets Bubble Image & Text Colors
            bubbleImageView.image = [self cellBackgroundImage];
            messageTextView.textColor = [self textMessageColor];
            lblTime.textColor = [self timeLabelColor];
            
            // Cancels image uploading
            if ( uploadRequest ) {
                [uploadRequest cancel];
                [self hideProgressOverlay];
            }
        } else {
            if ( oldStatus == MX_MESSAGE_STATUS_NOT_DELIVERED ) {
                // Resets Bubble Image & Text Colors
                bubbleImageView.image = [self cellBackgroundImage];
                messageTextView.textColor = [self textMessageColor];
                lblTime.textColor = [self timeLabelColor];
            }
        }
    }
}

- (void)setReadStatus {
    if ( sentMessage ) {
        if (!readStatusView) {
            readStatusView = [[UIImageView alloc] init];
            [self.contentView addSubview:readStatusView];
        }
        
        if ( [AppUtil isNotEmptyObject:_messageInfo[@"status"]] && [_messageInfo[@"status"] integerValue] == MX_MESSAGE_STATUS_READ )
            readStatusView.image = [UIImage imageNamed:@"read.png"];
        else
            readStatusView.image = nil;
    }
}

- (UIImage *)cellBackgroundImage {
    UIImage *bubbleImage = nil;
    if ( sentMessage ) {
        if ( [AppUtil isNotEmptyObject:_messageInfo[@"status"]] &&
            [_messageInfo[@"status"] integerValue] == MX_MESSAGE_STATUS_NOT_DELIVERED )
            bubbleImage = [UIImage imageNamed:@"sender_red_bubble.png"];
        else
            bubbleImage = [UIImage imageNamed:@"sender_bubble.png"];
    } else
        bubbleImage = [UIImage imageNamed:@"receiver_bubble.png"];

    return [bubbleImage resizableImageWithCapInsets:UIEdgeInsetsMake(18,22,16,25)
                                       resizingMode:UIImageResizingModeStretch];
}

- (UIColor *)textMessageColor {
    return sentMessage ? [UIColor whiteColor] : [UIColor blackColor];
}

- (UIColor *)timeLabelColor {
    UIColor *color = sentMessage ? [UIColor whiteColor] : [UIColor grayColor];
    
    return color;
}


#pragma mark - Measurement methods

+ (CGSize)bubbleSizeFromMessageInfo:(NSDictionary *)message_info {
    CGSize size = CGSizeZero, screenSize = [UIScreen mainScreen].bounds.size;
    
    BOOL textMessage = [message_info[@"type"] integerValue] == MX_MESSAGE_TYPE_TEXT;
    if ( !textMessage ) {
        size.width   = screenSize.width - kBubbleMarginLeftMin;
        size.height  = size.width * [message_info[@"height"] integerValue] / [message_info[@"width"] integerValue];
        size.height += kPhotoBubblePaddingTop;
    } else {
        UITextView *textView = [[UITextView alloc] init];
        textView.font = [UIFont fontWithName:@"HelveticaNeue" size:kBubbleFontSize];
        textView.text = [AppUtil isEmptyString:message_info[@"text"]] ? MX_MESSAGE_TEXT_SENT_FOR_DIFFERENT_DEVICE
                                                                      : message_info[@"text"];
        size          = [textView sizeThatFits:CGSizeMake(screenSize.width - kBubbleMarginLeftMin, FLT_MAX)];
        size.width    = MAX(size.width, kBubbleMinWidth);
        size.height  += kTextBubblePaddingTop-22; // -22: to remove the empty space from the calculated height
    }
    size.width  += kBubblePaddingLeft + kBubblePaddingRight;
    size.height += kBubblePaddingBottom+kBubbleMarginBottom;
    
    return size;
}

+ (CGFloat)cellHeightFromMessageInfo:(NSDictionary *)message_info {
    CGSize bubbleSize = [self bubbleSizeFromMessageInfo:message_info];
    return bubbleSize.height + kBubbleMarginBottom;
}


#pragma mark - Navigation

- (void)onContentClicked {
    if ( ![MXMessageUtil checkLocalImageExistsForMessage:_messageInfo] ) return;
    
    if ( [_messageInfo[@"type"] integerValue] == MX_MESSAGE_TYPE_PHOTO ) {
        //[MXImageBrowser showImage:thumbnailView];
        
        // Create image info
        JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
        imageInfo.image = thumbnailView.image;
        imageInfo.referenceRect = thumbnailView.frame;
        imageInfo.referenceView = containerView;
        imageInfo.referenceContentMode = thumbnailView.contentMode;
        imageInfo.referenceCornerRadius = thumbnailView.layer.cornerRadius;
        
        // Setup view controller
        JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                               initWithImageInfo:imageInfo
                                               mode:JTSImageViewControllerMode_Image
                                               backgroundStyle:JTSImageViewControllerBackgroundOption_None];
        
        // Present the view controller
        [imageViewer showFromViewController:[(MXChatController *)self.delegate pageRootVC]
                                 transition:JTSImageViewControllerTransition_FromOriginalPosition];

    }
}


#pragma mark - Image upload/download progress

- (void)hideProgressOverlay {
    [progressView displayOperationDidFinishAnimation];
    double delayInSeconds = progressView.stateChangeAnimationDuration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        progressView.progress = 0;
        progressView.hidden = YES;
    });
}

- (void)updateProgress {
    CGFloat progress = progressView.progress + 0.01;
    if (progress >= 1) {
        [timer invalidate];
        [progressView displayOperationDidFinishAnimation];
        double delayInSeconds = progressView.stateChangeAnimationDuration;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            progressView.progress = 0.;
            progressView.hidden = YES;
        });
    } else if(progress <= transferStatus ) {
        progressView.progress = progress;
    }
}


#pragma mark - Image upload

- (void)uploadAttachment {
    [progressView displayOperationWillTriggerAnimation];
    double delayInSeconds = progressView.stateChangeAnimationDuration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    });
    
    NSString *imageFileName = [MXMessageUtil imageFileNameByAppMessageId:_messageInfo[@"app_message_id"]];
    NSString *filePath = [MXMessageUtil temporaryPathByFileName:imageFileName];
    
    NSData *attachment = UIImageJPEGRepresentation(thumbnailView.image, 0.7f);
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
        attachment = [EncryptionUtil encryptAttachment:attachment forMessage:_messageInfo];
        [attachment writeToFile:filePath atomically:YES];
    }
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    
    uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = AWS_S3_BUCKET;
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    uploadRequest.key = [AWS_S3_BUCKET_TEMP_FOLDER stringByAppendingPathComponent:imageFileName];
    uploadRequest.body = fileURL;
    
    uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //Update progress.
            float t = ((float)totalBytesSent / (float)totalBytesExpectedToSend);
            transferStatus = t;
        });
    };
    
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    [[transferManager upload:uploadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor] withBlock:^id(AWSTask *task) {
        [self hideProgressOverlay];
        if (task.error) {
            NSLog(@"ERROR in uploadAttachment - %@", task.error);
        } else {
            NSString *imageUrl = [NSString stringWithFormat:@"https://%@.s3.amazonaws.com/%@/%@", AWS_S3_BUCKET, AWS_S3_BUCKET_TEMP_FOLDER, imageFileName];
            
            [self uploadedFileToS3AtPath:imageUrl];
        }
        return nil;
    }];
}

- (void)uploadedFileToS3AtPath:(NSString *)imageUrl {
    NSLog(@"Successfully uploaded: %@", imageUrl);
    
    [[ChatService instance] transferPhotoForMessage:_messageInfo completion:^(BOOL success, NSString *errorStatus) {
        if (success) {
            MXMessage *message = [MXMessage MR_findFirstByAttribute:@"app_message_id" withValue:_messageInfo[@"app_message_id"]];
            self.messageInfo = [MXMessageUtil dictionaryWithValuesFromMessage:message];
            
            // Removes the local temporary uploading file.
            NSString *imageFileName = [MXMessageUtil imageFileNameByAppMessageId:_messageInfo[@"app_message_id"]];
            NSString *filePath = [MXMessageUtil temporaryPathByFileName:imageFileName];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }];
}


#pragma mark - Image download

- (void)downloadAttachmentFromServer {
    
    [progressView displayOperationWillTriggerAnimation];
    double delayInSeconds = progressView.stateChangeAnimationDuration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    });
    
    if ( [_messageInfo[@"type"] integerValue] == MX_MESSAGE_TYPE_PHOTO ) {
        TCBlobDownloadManager *sharedManager = [TCBlobDownloadManager sharedInstance];
        NSURL *fileURL = [NSURL URLWithString:_messageInfo[@"url"]];
        NSString *customPath = [MXMessageUtil temporaryDownloadPathByAppMessageId:_messageInfo[@"app_message_id"]];
        [sharedManager startDownloadWithURL:fileURL customPath:customPath firstResponse:^(NSURLResponse *response) {
            
        } progress:^(uint64_t receivedLength, uint64_t totalLength, NSInteger remainingTime, float progress) {
            transferStatus = progress;
            NSLog(@"Downloading %%%.0f... image at: %@", progress * 100.f, _messageInfo[@"url"]);
            
        } error:^(NSError *error) {
            NSLog(@"ERROR - %@", error.description);
            
        } complete:^(BOOL downloadFinished, NSString *pathToFile) {
            [self downloadedFileAtPath:pathToFile];
        }];
    }
}

- (void)downloadedFileAtPath:(NSString *)pathToTempFile {
    
    NSString *status_read = [@(MX_MESSAGE_STATUS_READ) stringValue];
    [[ChatService instance] updateReceivedMessagesStatus:status_read
                                          forAppMessages:@[_messageInfo[@"app_message_id"]]
                                              completion:^(BOOL success) {
                                                  
        if ( success ) {
            
            NSString *filename = [MXMessageUtil imageFileNameByAppMessageId:_messageInfo[@"app_message_id"]];
            
            // Moves the downloaded file from temporary path to the destination path.
            NSString *toPath = [AppUtil imagePathWithFileName:filename];
            NSError *error = nil;
            if ( [[NSFileManager defaultManager] copyItemAtPath:pathToTempFile toPath:toPath error:&error] == NO ) {
                NSLog(@"ERROR: failed to copy file from: %@ to local path: %@", pathToTempFile, toPath);
            } else {
                // Removes the temporary download directory and its contents.
                NSString *customPath = [MXMessageUtil temporaryDownloadPathByAppMessageId:_messageInfo[@"app_message_id"]];
                [[NSFileManager defaultManager] removeItemAtPath:customPath error:nil];
                
                // Prevents the file to be backed up to iCloud and iTunes
                [AppUtil addSkipBackupAttributeToItemAtPath:toPath];
            }
            
            NSDictionary *info = @{@"app_message_id": _messageInfo[@"app_message_id"],
                                   @"type": @(MX_MESSAGE_TYPE_PHOTO),
                                   @"filename": filename,
                                   @"url": @"",
                                   @"status": @(MX_MESSAGE_STATUS_READ)};

            [MXMessageUtil saveMessageByInfo:info attachment:nil completion:^(NSString *app_message_id, NSString *sharedKeyString, NSError *error) {
                if ( !error ) {
                    _messageInfo[@"filename"] = filename;
                    _messageInfo[@"status"] = @(MX_MESSAGE_STATUS_READ);
                    thumbnailView.image = [MXMessageUtil imageOfMessage:_messageInfo];
                    
                    [self.delegate chatCellDidUpdateMessageInfo:_messageInfo];
                    
                    NSLog(@"MXChatCell > downloadedImage: %@", [AppUtil imagePathWithFileName:_messageInfo[@"filename"]]);
                }
            }];
        }
    }];
}

@end
