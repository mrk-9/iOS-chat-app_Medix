//
//  EncryptionUtil.h
//  MedX
//
//  Created by Ping Ahn on 9/23/15.
//  Copyright © 2015 Hugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EncryptionUtil : NSObject

#pragma mark - Key Generation

/**
 * Generates public/private key pair
 * @author Ping Ahn
 *
 * @return Array of base64 encoded string of public key, and private key data
 */
+ (NSArray *)generateKeyPair;

/**
 * Generates base64-encoded AES key string
 * @author Ping Ahn
 *
 * @return String base64-encoded of AES key data
 */
+ (NSString *)generateSharedAESKey;


#pragma mark - Basic Encryption/Decryption

/**
 * Encrypts data by a RSA public key
 * @author Ping Ahn
 *
 * @param originalData NSData to be encrypted
 *
 * @return NSData encrypted with originalData
 */
+ (NSData *)encryptData:(NSData *)originalData
            byPublicKey:(MIHRSAPublicKey *)publicKey;

/**
 * Decrypts data by a RSA private key
 * @author Ping Ahn
 *
 * @param encryptedData NSData to be decrypted
 *
 * @return NSData decrypted from encryptedData
 */
+ (NSData *)decryptData:(NSData *)encryptedData
           byPrivateKey:(MIHRSAPrivateKey *)privateKey;


#pragma mark - Text Encryption

/**
 * Encrypts text by a RSA public key
 * @author Ping Ahn
 *
 * @param text String of text to encrypt
 * @param publicKey MIHRSAPublicKey for encryption
 *
 * @return String of base64-encoded encrypted data
 */
+ (NSString *)encryptText:(NSString *)text byPublicKey:(MIHRSAPublicKey *)publicKey;


#pragma mark - Text Decryption

/**
 * Decrypts an encrypted text by a RSA private key
 * @author Ping Ahn
 *
 * @param encryptedText String of base64-encoded encrypted data
 * @param privateKey MIHRSAPrivateKey for decryption
 *
 * @return String of decrypted UTF-8 text
 */
+ (NSString *)decryptText:(NSString *)encryptedText
             byPrivateKey:(MIHRSAPrivateKey *)privateKey;

/**
 * Decrypts a local stored encrypted text by current user's RSA private key
 */
+ (NSString *)decryptLocalText:(NSString *)encryptedText;


#pragma mark - Photo Encryption

/**
 * Encrypts an image attachment by shared AES key
 * @author Ping Ahn
 *
 * @param attachment NSData of image
 * @param sharedKeyString String base64-encoded of shared AES key
 *
 * @return NSData of encrypted image attachment by shared AES key
 */
+ (NSData *)encryptAttachment:(NSData *)attachment
              sharedKeyString:(NSString *)sharedKeyString;


/**
 * Encrypts attachment for a message to send to its recipient
 * @author Ping Ahn
 *
 * @param attachment NSData of image
 * @param message NSDictionary
 *
 * @return NSData of encrypted image attachment for message recipient
 */
+ (NSData *)encryptAttachment:(NSData *)attachment
                   forMessage:(NSDictionary *)message_info;

#pragma mark - Photo Decryption

/**
 * Decrypts a local stored encrypted image attachment by shared AES key
 */
+ (NSData *)decryptLocalAttachment:(NSData *)encryptedAttachment
                   sharedKeyString:(NSString *)sharedKeyString;

@end
