//
//  EncryptionUtil.m
//  MedX
//
//  Created by Ping Ahn on 9/23/15.
//  Copyright © 2015 Hugo. All rights reserved.
//

#import "EncryptionUtil.h"

@implementation EncryptionUtil

#pragma mark - Key Generation

+ (NSArray *)generateKeyPair {
    MIHRSAKeyFactory *factory = [[MIHRSAKeyFactory alloc] init];
    [factory setPreferedKeySize:MIHRSAKey4096];
    
    MIHKeyPair *keyPair = [factory generateKeyPair];
    MIHRSAPublicKey *publicKey = keyPair.public;
    MIHRSAPrivateKey *privateKey = keyPair.private;
    
    return @[[publicKey.dataValue base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength],
             privateKey.dataValue];
}

+ (NSString *)generateSharedAESKey {
    MIHAESKeyFactory *factory = [[MIHAESKeyFactory alloc] init];
    MIHAESKey *sharedKey = [factory generateKey];
    
    return [sharedKey.dataValue base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}


#pragma mark - Basic Encryption/Decryption

+ (NSData *)encryptData:(NSData *)originalData byPublicKey:(MIHRSAPublicKey *)publicKey {
    NSError *encryptionError = nil;
    NSData *encryptedData = [publicKey encrypt:originalData error:&encryptionError];
    
    return encryptedData;
}

+ (NSData *)decryptData:(NSData *)encryptedData byPrivateKey:(MIHRSAPrivateKey *)privateKey {
    NSError *decryptionError = nil;
    NSData *decryptedData = [privateKey decrypt:encryptedData error:&decryptionError];
    
    return decryptedData;
}


#pragma mark - Text Encryption

+ (NSString *)encryptText:(NSString *)text byPublicKey:(MIHRSAPublicKey *)publicKey {
    NSData *messageData = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [self encryptData:messageData byPublicKey:publicKey];
    
    NSString *base64EncryptedDataString = [encryptedData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    return base64EncryptedDataString;
}


#pragma mark - Text Decryption

+ (NSString *)decryptText:(NSString *)encryptedText byPrivateKey:(MIHRSAPrivateKey *)privateKey {
    NSData *encryptedData = [NSData dataFromBase64String:encryptedText];
    NSData *decryptedData = [self decryptData:encryptedData byPrivateKey:privateKey];
    
    NSString *decryptedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    return decryptedString;
}

+ (NSString *)decryptLocalText:(NSString *)encryptedText {
    MedXUser *currentUser = [MedXUser CurrentUser];
    if ( !currentUser.privateKey ) return encryptedText;
    
    return [self decryptText:encryptedText byPrivateKey:currentUser.privateKey];
}


#pragma mark - Photo Encryption

+ (NSData *)encryptAttachment:(NSData *)attachment sharedKeyString:(NSString *)sharedKeyString {
    NSError *encryptError;
    MIHAESKey *sharedKey = [[MIHAESKey alloc] initWithData:[NSData dataFromBase64String:sharedKeyString]];
    
    return [sharedKey encrypt:attachment error:&encryptError];
}

+ (NSData *)encryptAttachment:(NSData *)attachment forMessage:(NSDictionary *)message_info {
    NSData *data = attachment;
    MXUser *recipient = [MXUser MR_findFirstByAttribute:@"user_id" withValue:message_info[@"recipient_id"]];
    if ( [message_info[@"is_encrypted"] isEqualToString:@"1"] && [AppUtil isNotEmptyString:recipient.public_key] ) {
        
        // Encrypts the attachment data by shared AES key
        data = [EncryptionUtil encryptAttachment:data sharedKeyString:message_info[@"text"]];
    }
    return data;
}


#pragma mark - Photo Decryption

+ (NSData *)decryptLocalAttachment:(NSData *)encryptedAttachment sharedKeyString:(NSString *)sharedKeyString {
    
    if ( [AppUtil isEmptyObject:sharedKeyString] ) return encryptedAttachment;
    
    MedXUser *currentUser = [MedXUser CurrentUser];
    if ( !currentUser.privateKey ) return encryptedAttachment;
    
    // Decrypts encrypted attachment data by shared key
    NSError *decryptError = nil;
    MIHAESKey *sharedKey = [[MIHAESKey alloc] initWithData:[NSData dataFromBase64String:sharedKeyString]];
    NSData *decryptedAttachmentData = [sharedKey decrypt:encryptedAttachment error:&decryptError];
    
    return decryptedAttachmentData;
}

@end
