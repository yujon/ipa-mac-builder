//
//  ALTCertificateRequest.h
//  AltSign
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALTCertificateRequest : NSObject

@property (nonatomic, copy, readonly) NSData *data;
@property (nonatomic, copy, readonly) NSData *privateKey;

- (nullable instancetype)init;

@end

NS_ASSUME_NONNULL_END
